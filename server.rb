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
require 'lib/parsers/hostname_parser'
require 'lib/parsers/shop_parser'
require 'lib/renderers/log_renderer'
# comment out until 1.8.6 is installed on server
#Dir['lib/*.rb', 'lib/parsers/*.rb', 'lib/renderers/*.rb'].each { |file| require file }

CONFIG    = YAML.load( File.read(File.join(File.dirname(__FILE__), 'config', 'config.yml')) )
LOG_FILES = CONFIG['log_files'] rescue []
USERNAME  = CONFIG['username'] rescue 'admin'
PASSWORD  = CONFIG['password'] rescue 'admin'


module GrepRenderer  
  attr_accessor :response, :parser, :marker, :params

  def parser
    @parser ||= TimeParser.new( HostnameParser.new(ShopParser.new), @params)
  end
  
  def renderer
    @renderer ||= LogRenderer.new
  end
  
  # once download is complete, send it to client
  def receive_data(data)
    @buffer ||= StringScanner.new("")
    @buffer << data
    
    html = ""
    while line = @buffer.scan_until(/\n/)
      tokens = parser.parse(line)
      html << renderer.render(tokens)
    end
    
    return if html.empty?
    
    response.chunk html
    response.send_chunks
  end

  def unbind
    response.chunk '</div><hr><p id="done">Done</p></body></html>\n'
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
    LOG_FILES.map {|f| Dir[f] }.flatten.compact.uniq.select{|f| File.file?(f) }.sort
  end
  
  def parse_params
    ENV['QUERY_STRING'].split('&').inject({}) {|p,s| k,v = s.split('=');p[k.to_s] = CGI.unescape(v.to_s);p}
  end


  def unbind
    return unless @grepper
    kill_processes(@grepper.get_status.pid)
    close_connection
    puts 'UNBIND'
  end
 
  def kill_processes(ppid)
    return if ppid.nil?
    all_pids = [ppid] + get_child_pids(ppid).flatten.uniq.compact
    puts "=== pids are #{all_pids.inspect}"
    all_pids.each do |pid|
      Process.kill('TERM',pid.to_i)
      puts "=== killing #{pid}"
    end
  rescue Exception => e
    puts "!Error killing processes: #{e}"
  end
    
  def get_child_pids(ppid)
    out = `ps -opid,ppid | grep #{ppid.to_s}`
    ids = out.split("\n").map {|line| $1 if line =~ /^\s*([0-9]+)\s.*/ }.compact
    ids.delete(ppid.to_s)
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
    puts "params: #{@params.inspect}"
    
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
      response = init_chunk_response
      EventMachine::add_periodic_timer(1) do 
        response.chunk "Lorem ipsum dolor sit amet<br/>"        
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
    respond_with(500, error_page(e))
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
    headers.each_pair {|h, v| response.headers[h] = v }
    response.status  = status
    response.content = content
    response.send_response
  end
  
  private
  
  def error_page(error)
    @error = error
    render "error.html.erb"
  end
  
  def welcome_page
    render "index.html.erb"
  end
  
  def results_page
    render "index.html.erb"
  end  
  
  def render(view)
    @toolbar = template("_toolbar.html.erb")
    @content_for_header = template("_header.html.erb")
    template(view)
  end
  
  def template(filename)
    content = File.read( File.join(File.dirname(__FILE__), 'views', filename) ) 
    ERB.new(content).result(binding)
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


