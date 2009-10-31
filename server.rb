$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'erb'
require 'cgi'
require 'yaml'
require 'base64'
require 'optparse'
require 'lib/basic_auth'
require 'lib/mime_types'
require 'lib/string_ext'
require 'lib/commands/command_builder'
require 'lib/commands/tail_command_builder'
require 'lib/parsers/time_parser'
require 'lib/parsers/hostname_parser'
require 'lib/parsers/shop_parser'
require 'lib/renderers/log_renderer'

$options = {
  :username => nil,
  :password => nil,
  :log_files => ['**/*.log*'],
  :port => 8080,
  :address => "0.0.0.0"
}

ARGV.options do |opts|
  opts.banner = "Usage:  #{File.basename($PROGRAM_NAME)} [options] [directory]"
  
  opts.separator " "
  opts.separator "Specific options:"

  opts.on( "-f", "--config [file]", String, "Config file (yml)" ) do |opt|
    $options.update YAML.load_file( opt )
  end
  
  opts.on( "-p", "--port [port]", Integer, "Port to listen on" ) do |opt|
    $options[:port] = opt
  end  

  opts.on( "-b", "--address [address]", String, "Address to bind to (default 0.0.0.0)" ) do |opt|
    $options[:address] = opt
  end  

  opts.on( "--include [mask]", String, "File mask of logs to add (default: **/*.log*)" ) do |opt|
    $options[:log_files] ||= []
    $options[:log_files] += opt
  end

  opts.separator " "
  opts.separator "Password protection:"

  opts.on( "--username [USER]", String, "Optional username (httpauth)." ) do |opt|
    $options[:username] = opt
  end
    
  opts.on( "--password [PASS]", String, "Optional password (httpauth)." ) do |opt|
    $options[:password] = opt
  end
    
  opts.separator " "
  opts.separator "Misc:"
  
  opts.on( "-h", "--help", "Show this message." ) do
    puts opts
    exit
  end

  opts.separator " "
  
  begin
    opts.parse!
  rescue
    puts opts
    exit
  end
end

module GrepRenderer  
  attr_accessor :response, :parser, :marker, :params

  def parser
    @parser ||= TimeParser.new( HostnameParser.new(ShopParser.new), params)
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
    response.chunk '</div><hr><p id="done">Done</p></body></html>'
    response.chunk ''
    response.send_chunks
    puts 'Done'
  end
end



class Handler < EventMachine::Connection
  include EventMachine::HttpServer
  include BasicAuth
  
  LeadIn    = ' ' * 1024 
  
  def process_http_request    
    authenticate!
    
    puts "action: #{action}"
    puts "params: #{params.inspect}"
    
    case action
    when '/'
      respond_with(200, welcome_page)

    when '/perform'
      if params.empty?
        respond_with(200, welcome_page)
      else
        # get command
        command = case params['tool']
          when 'grep' then CommandBuilder.new(params).command
          when 'tail' then TailCommandBuilder.new(params).command
          else raise InvalidParameterError, "Invalid Tool parameter"
        end
        response = init_chunk_response
        response.chunk results_page # display page header
        
        puts "Running: #{command}"
        EventMachine::popen(command, GrepRenderer) do |grepper|
          @grepper = grepper          
          @grepper.marker = 0
          @grepper.params = params
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
    headers = { "WWW-Authenticate" => %(Basic realm="Clarity")}
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
    p headers
    response.content = content
    response.send_response
  end
    
  def unbind
    return unless @grepper
    kill_processes(@grepper.get_status.pid)
    close_connection
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
  
  def logfiles
    $options[:log_files].map {|f| Dir[f] }.flatten.compact.uniq.select{|f| File.file?(f) }.sort
  end

  def authenticate!
    login, pass = authentication_data
    
    p authentication_data
        
    if ($options[:username] && $options[:username] != login) || ($options[:password] && $options[:password] != pass)    
      raise NotAuthenticatedError
    end
    
    true
  end
  
  def params
    @params ||= ENV['QUERY_STRING'].split('&').inject({}) {|p,s| k,v = s.split('=');p[k.to_s] = CGI.unescape(v.to_s);p}
  end  
  
  def action
    @action ||= ENV["PATH_INFO"]
  end
end

class InvalidParameterError < StandardError; end
class NotFoundError < StandardError; end
class NotAuthenticatedError < StandardError; end


EventMachine::run {
  EventMachine.epoll
  EventMachine::start_server($options[:address], $options[:port], Handler)
  puts "Listening #{$options[:address]}:#{$options[:port]}..."
  puts "Adding log files: #{$options[:log_files].inspect}"
}


