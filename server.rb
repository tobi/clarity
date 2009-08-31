$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'erb'
require 'cgi'
require 'yaml'
require 'base64'
require 'lib/basic_auth'
require 'lib/mime_types'
require 'lib/string_ext'
require 'lib/command_builder'
require 'lib/search_command_builder'
require 'lib/tail_command_builder'
require 'lib/parsers/time_parser'
require 'lib/parsers/shopify_log_parser'
require 'lib/parsers/shopify_shop_parser'
require 'lib/renderers/shopify_log_renderer'
# comment out until 1.8.6 is installed on server
#Dir['lib/*.rb', 'lib/parsers/*.rb', 'lib/renderers/*.rb'].each { |file| require file }

config = File.read(File.join(File.dirname(__FILE__), 'config', 'config.yml'))
CONFIG    = YAML.load(config)
LOG_FILES = CONFIG['log_files'] rescue []
USERNAME  = CONFIG['username'] rescue 'admin'
PASSWORD  = CONFIG['password'] rescue 'admin'
  
# sample log output
# Jul 24 14:58:21 app3 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 
#

module GrepRenderer  
  attr_accessor :response, :parser, :marker, :params

  def detect_parser(line)
    shop_parser = ShopifyShopParser.new
    log_parser = ShopifyLogParser.new(shop_parser)
    parser = TimeParser.new(log_parser, @params)
    parser
  end
  
  def detect_renderer(parser)
    ShopifyLogRenderer.new
  end
  
  # once download is complete, send it to client
  def receive_data(data)
    @buffer ||= StringScanner.new("")
    @buffer << data

    html = "<div id='#{@marker += 1}'>"
    while line = @buffer.scan_until(/\n/)
      @parser   ||= detect_parser(line) unless @parser
      @renderer ||= detect_renderer(@parser) unless @renderer  # base render based on the parser
      
      elements = @parser.parse(line)
      out = @renderer.render(elements)
      html << out 
    end
    response.chunk html + "</div>"
    response.send_chunks
  end

  def unbind
    response.chunk '<hr><p id="done">Done</p></body></html>'
    response.chunk ''
    response.send_chunks
    puts 'Done'
  end
  
end



class Handler < EventMachine::Connection
  include EventMachine::HttpServer
  include BasicAuth
  
  AuthRequired  = [ "/", "/test", "/tail", "/search"] #actions that require authentication
  LeadIn    = ' ' * 1024 
  
  def logfiles
    LOG_FILES.map {|f| Dir[f] }.flatten.compact.uniq.select{|f| File.file?(f) }
  end
  
  def parse_params
    params = ENV['QUERY_STRING'].split('&').inject({}) {|p, s| k,v=s.split('=');p[k.to_s]=CGI.unescape(v.to_s);p}
    puts "params #{params.inspect}"
    params
  end

  def welcome_page
    render("index.html.erb")
  end
  
  def results_page
    render 'index.html.erb'
  end
  
  def tail_page
    render 'tail.html.erb'
  end
  
  def unbind
    if @grepper
      kill_processes(@grepper.get_status.pid)
      close_connection
      puts 'UNBIND'
    else
      puts 'nothing to close'
    end
  end
 
  def kill_processes(ppid)
    return if ppid.nil?
    puts "find all processes for #{ppid}:"
    all_pids = [ppid] + get_child_pids(ppid).flatten.uniq.compact
    puts "all pids are #{all_pids.inspect}"
    all_pids.each do |pid|
      Process.kill('TERM',pid.to_i)
      puts "killing #{pid}"
    end
  rescue Exception => e
    puts "!Error killing processes: #{e}"
  end
    
  def get_child_pids(ppid)
    ppid = ppid.to_s
    out = `ps -opid,ppid | grep #{ppid}`
    ids = out.split("\n").map do |line|
      $1 if line =~ /^\s*([0-9]+)\s.*/
    end.compact
    ids.delete(ppid)
    if ids.empty?
      ids
    else
      ids << ids.map {|id| get_child_pids(id) }
    end
  end

  def process_http_request
    action = ENV["PATH_INFO"]
    puts "got #{action}"
    authenticate!(@http_headers) if AuthRequired.include?(action)
    
    @params = parse_params
    
    case action
    when '/'
      respond_with(200, welcome_page)

    when '/perform'
      if @params.empty?
        respond_with(200, welcome_page)
      else
        # get command
        command = case @params['tool']
          when 'grep' then SearchCommandBuilder.build_command(@params)
          when 'tail' then TailCommandBuilder.build_command(@params)
          else raise InvalidParameterError, "Invalid Tool parameter"
        end
        response = init_chunk_response
        response.chunk results_page # display page header
        
        puts "Running: #{command}"
        EventMachine::popen(command, GrepRenderer) do |grepper|
          @grepper = grepper          
          @grepper.marker = 0
          @grepper.params = @params
          @grepper.response = response 
        end
      end
      
    when '/test'
      authenticate!(@http_headers)
      response = init_chunk_response
      EventMachine::add_periodic_timer(1) do 
        response.chunk "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Hello chunked world <br/>"        
        response.send_chunks
      end
    
    else
      # DEFAULT - assume requests for assets (images, js)
      requested_file = File.join(File.dirname(__FILE__), "public", ENV["PATH_INFO"])
      if File.exists?(requested_file)
        respond_with(200, File.open(requested_file).read, :content_type => Mime::TYPES[File.extname(requested_file)])
      else
        raise NotFoundError
      end
    end

  rescue InvalidParameterError => e
    @error = e
    page   = render 'error.html.erb'
    respond_with(500, page)
  rescue NotFoundError => e
    respond_with(404, "<h1>Not Found</h1>")
  rescue NotAuthenticatedError => e
    puts "Could not authenticate user"
    headers = { "WWW-Authenticate" => %(Basic realm="Application")}
    respond_with(401, "HTTP Basic: Access denied.\n", :content_type => 'text/plain', :headers => headers)
  end
  
  
  def init_chunk_response
    response = EventMachine::DelegatedHttpResponse.new( self )
    response.status = 200
    response.headers['Content-Type'] = 'text/html'
    response.chunk LeadIn
    response
  end
  
  def respond_with(status, content, options = {})
    response = EventMachine::DelegatedHttpResponse.new( self )
    response.headers['Content-Type'] = options.fetch(:content_type, 'text/html')
    headers = options.fetch(:headers, {})
    headers.each_pair do |header, value| 
      response.headers[header] = value
    end
    response.status  = status
    response.content = content
    response.send_response
  end
  
  private
  def render(view)
    template = File.read(File.join(File.dirname(__FILE__), 'views', view))
    ERB.new(template).result(binding)
  end
  
end

class InvalidParameterError < StandardError; end
class NotFoundError < StandardError; end
class NotAuthenticatedError < StandardError; end


EventMachine::run {
  EventMachine.epoll
  EventMachine::start_server("0.0.0.0", CONFIG['port'] || 8080, Handler)
  puts "Listening..."
  puts "Valid log files are #{LOG_FILES.inspect}"
}


