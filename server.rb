require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'erb'
require 'cgi'
require 'yaml'

class String #:nodoc:
  def blank?
    self !~ /\S/
  end
end

LOG_FILES = YAML.load(open('./config/config.yml').read)['log_files'] rescue [] 

# sample log output
# Jul 24 14:58:21 app3 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 

module GrepRenderer  
  attr_accessor :response
  
  # once download is complete, send it to client
  def receive_data(data)
    # parse it nicely
    response.chunk ERB::Util.h(data).gsub(/\n/, '<br/>')
    response.send_chunks
  end

  def unbind
    response.chunk '<hr><p id="done">Done</p></body></html>'
    response.chunk ''
    response.send_chunks
    puts 'Done'
  end
  
end

class RailsLineParser
  
  def modify(line)
    line + '<br/>'
    
    if line =~ /([\w\/\.])\:(\s*\d\d\:\d\d:\d\d)\s*(.*)/
      "#{File.basename($1)} #{Time.parse($2)} #{$3}"
    end
  end
end


class Handler  < EventMachine::Connection
  LeadIn = ' ' * 1024
  
  include EventMachine::HttpServer
  
  def logfiles
    @@logfiles = LOG_FILES.map {|f| Dir[f] }.flatten.compact.uniq
  end
  
  def parse_params
    params = ENV['QUERY_STRING'].split('&').inject({}) {|p, s| k,v=s.split('=');p[k.to_s]=CGI.unescape(v.to_s);p}
    puts "params #{params.inspect}"
    params
  end

  def welcome_page
    @@welcome_page ||= ERB.new(open('./views/index.html.erb').read).result(binding)
  end
  
  def results_page
    @@results_page = ERB.new(open('./views/index.html.erb').read).result(binding)
  end
 
  # tool - zgrep, bzgrep or grep
  # base query
  # shop filter
  # ..additional filters
  def build_grep_request(params)
    tool = case
      when @params['file'].include?('.gz') then 'zgrep'
      when @params['file'].include?('.bz2') then 'bzgrep'
      else 'grep'
    end
    
    query       = @params['q']
    shop        = @params['shop']
    logfile     = @params['file']

    # get shop name (future)
    # raise error if attempt unauthorized file
    raise InvalidParameterError, "invalid log file #{params['file']}" unless logfiles.include?(params['file'])
    raise InvalidParameterError, "Both Shop URL and Query cannot be blank" if query.blank? && shop.blank?
    raise InvalidParameterError, "Query cannot be blank" if query.blank?
    
    cmd  = "#{tool} #{query.inspect} #{logfile} "
    cmd << shop_filter(@params) unless shop.blank?
    cmd.strip
    %[sh -c "#{cmd}"]
  end
 
  def shop_filter(params)
    "| grep #{params['shop'].inspect}"
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
      @params = parse_params || {}
      if @params['q'].nil? || @params['file'].nil?
        response.content = welcome_page
        response.send_response
      else
        # Safari only starts rendering chunked data after it gets 1kb of data. 
        # So we sent it 1kb of whitespace
        response.chunk LeadIn
        response.chunk results_page # display page header
        

        cmd = build_grep_request(@params)
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
    @error = e    
    response.content = ERB.new(open('./views/error.html.erb').read).result(binding)
    response.headers['Content-Type'] = 'text/html'
    response.send_response
  end
  
end

class InvalidParameterError < StandardError; end

EventMachine::run {
  EventMachine.epoll
  EventMachine::start_server("0.0.0.0", 8080, Handler)
  puts "Listening..."
  puts "Valid log files are #{LOG_FILES.inspect}"
}
