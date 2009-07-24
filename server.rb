require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'erb'
require 'cgi'

LOG_PREFIX = '/var/log'
LOG_FILES  = %W{ rails.log.* user.log.* }

puts "Usage: #{$0}"
puts

if ARGV[0]
  puts "  Looking for valid log files in #{LOG_PREFIX}"
  puts
end



module GrepRenderer  
  attr_accessor :response
  
  # once download is complete, send it to client    
  def receive_data(data)
    # parse it nicely
    response.chunk ERB::Util.h(data).gsub(/\n/, '<br/>')
    response.send_chunks
  end

  def unbind
    response.chunk ''
    response.send_chunks
    puts 'Done'
  end
  
end
 
class Handler  < EventMachine::Connection
  LeadIn = ' ' * 1024
  
  include EventMachine::HttpServer
  
  def logfiles
    @@logfiles = LOG_FILES.map {|f| Dir[File.join(LOG_PREFIX, f)] }.flatten.compact.uniq
  end
  
  def parse_params
    params = ENV['QUERY_STRING'].split('&').inject({}) {|p, s| k,v=s.split('=');p[k.to_s]=CGI.unescape(v.to_s);p}
    # get shop name (future)
    # raise error if attempt unauthorized file
    raise InvalidParameterError, "invalid log file #{params['file']}" unless logfiles.include?(params['file'])
    params
  end

  def welcome_page
    @@welcome_page ||= ERB.new(open('./views/index.html.erb').read).result(binding)
  end
  
  def results_page
    @@results_page = ERB.new(open('./views/index.html.erb').read).result(binding)
  end
 
  def process_http_request
    response = EventMachine::DelegatedHttpResponse.new( self )
    response.headers['Content-Type'] = 'text/html'
    response.status = 200
    
    case ENV["PATH_INFO"]
    when '/'
      response.headers['Content-Type'] = 'text/html'
      response.content = welcome_page
      response.send_response
      
    when '/search'      
      @params = parse_params
      if @params['q'].nil? || @params['file'].nil?
        response.content = 'Missing parameters "q" or "file"'
        response.send_response
      else            
        # Safari only starts rendering chunked data after it gets 1kb of data. 
        # So we sent it 1kb of whitespace
        response.chunk LeadIn
        response.chunk results_page # display page header
        
        tool = case
        when @params['file'].include?('.gz') then 'zgrep'
        when @params['file'].include?('.bz2') then 'bzgrep'
        else 'grep'
        end
                  
        cmd  = "#{tool} #{@params['q'].inspect} #{@params['file']}"        
        puts "Running: #{cmd}"
        
        EventMachine::popen(cmd, GrepRenderer) do |grepper|         
          grepper.response = response 
        end
      end
      
    when '/test'
      
      response.chunk LeadIn
                
      EventMachine::add_periodic_timer(1) do 
        response.chunk "Hello chunked world <br/>"        
        response.send_chunks
      end
            
    else
      response.status = 404
      response.content = "<h1>Not Found</h1>"
      response.headers['Content-Type'] = 'text/html'
      response.send_response      
    end
  rescue InvalidParameterError => e
    response.status = 500
    response.content = "<h1>Invalid Parameter Error</h1> #{e}"
    response.headers['Content-Type'] = 'text/html'
    response.send_response
  end
  
end

class InvalidParameterError < StandardError; end

EventMachine::run {
  EventMachine.epoll
  EventMachine::start_server("0.0.0.0", 8080, Handler)
  puts "Listening..."
}
