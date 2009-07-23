require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'erb'
require 'cgi'

puts "Usage: #{$0} \"/var/log/*\""
puts

if ARGV[0]
  $mask = ARGV[0] || 'files/*'
  puts "  Looking for log files in #{$mask}"
  puts
  
end


module GrepRenderer  
  attr_accessor :response
  
  # once download is complete, send it to client    
  def receive_data(data)
    response.chunk data.gsub(/\n/, "<br/>\n")
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
  
  def parse_params
    ENV['QUERY_STRING'].split('&').inject({}) {|p, s| k,v=s.split('=');p[k.to_s]=CGI.unescape(v.to_s);p}
  end
  
  def welcome_page
    @@welcome_page ||= ERB.new(DATA.read).result(binding)
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
      params = parse_params      
      
      if params['q'].nil? || params['file'].nil?
        response.content = 'Missing parameters "q" or "file"'
        response.send_response
      else            
        # Safari only starts rendering chunked data after it gets 1kb of data. 
        # So we sent it 1kb of whitespace
        response.chunk LeadIn
        
        tool = case
        when params['file'].include?('.gz') then 'zgrep'
        when params['file'].include?('.bz2') then 'bzgrep'
        else 'grep'
        end
                  
        cmd  = "#{tool} #{params['q'].inspect} #{params['file']}"        
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
  end
end
 
EventMachine::run {
  EventMachine.epoll
  EventMachine::start_server("0.0.0.0", 8080, Handler)
  puts "Listening..."
}



__END__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Search Server</title>
    <style type="text/css" media="screen">
      body {
        margin: 0;
        margin-bottom: 25px;
        padding: 0;
        background-color: #f0f0f0;
        font-family: "Lucida Grande", "Bitstream Vera Sans", "Verdana";
        font-size: 13px;
        color: #333;
      }
      
      h1 {
        font-size: 28px;
        color: #000;
      }
      
      a  {color: #03c}
      a:hover {
        background-color: #03c;
        color: white;
        text-decoration: none;
      }
      
      
      #page {
        background-color: #f0f0f0;
        width: 750px;
        margin: 0;
        margin-left: auto;
        margin-right: auto;
      }
      
      #content {
        float: left;
        background-color: white;
        border: 3px solid #aaa;
        padding: 25px;
        width: 500px;
      }
      
      #sidebar {
        float: right;
        width: 175px;
      }

      #footer {
        clear: both;
      }
      

      #header, #about, #getting-started {
        padding-left: 75px;
        padding-right: 30px;
      }


      #header {
        height: 64px;
      }
      #header h1, #header h2 {margin: 0}
      #header h2 {
        color: #888;
        font-weight: normal;
        font-size: 16px;
      }
      
      
      #about h3 {
        margin: 0;
        margin-bottom: 10px;
        font-size: 14px;
      }
      
      #about-content {
        background-color: #ffd;
        border: 1px solid #fc0;
        margin-left: -11px;
      }
      #about-content table {
        margin-top: 10px;
        margin-bottom: 10px;
        font-size: 11px;
        border-collapse: collapse;
      }
      #about-content td {
        padding: 10px;
        padding-top: 3px;
        padding-bottom: 3px;
      }
      #about-content td.name  {color: #555}
      #about-content td.value {color: #000}
      
      #about-content.failure {
        background-color: #fcc;
        border: 1px solid #f00;
      }
      #about-content.failure p {
        margin: 0;
        padding: 10px;
      }
      
      
      #getting-started {
        border-top: 1px solid #ccc;
        margin-top: 25px;
        padding-top: 15px;
      }
      #getting-started h1 {
        margin: 0;
        font-size: 20px;
      }
      #getting-started h2 {
        margin: 0;
        font-size: 14px;
        font-weight: normal;
        color: #333;
        margin-bottom: 25px;
      }
      #getting-started ol {
        margin-left: 0;
        padding-left: 0;
      }
      #getting-started li {
        font-size: 18px;
        color: #888;
        margin-bottom: 25px;
      }
      #getting-started li h2 {
        margin: 0;
        font-weight: normal;
        font-size: 18px;
        color: #333;
      }
      #getting-started li p {
        color: #555;
        font-size: 13px;
      }
      
      
      #search {
        margin: 0;
        padding-top: 10px;
        padding-bottom: 10px;
        font-size: 11px;
      }
      #search input {
        font-size: 11px;
        margin: 2px;
      }
      #search-text {width: 170px}
      
      
      #sidebar ul {
        margin-left: 0;
        padding-left: 0;
      }
      #sidebar ul h3 {
        margin-top: 25px;
        font-size: 16px;
        padding-bottom: 10px;
        border-bottom: 1px solid #ccc;
      }
      #sidebar li {
        list-style-type: none;
      }
      #sidebar ul.links li {
        margin-bottom: 5px;
      }
      
    </style>  
  </head>
  <body>
    <div id="page">
      <div id="sidebar">
      </div>

      <div id="content">
        
        
        <li>
          <form id="search" action="/search" method="get">
            <input type="hidden" name="hl" value="en" />
            Log file: <br />
            <select name="file">
              <%=  Dir[$mask].collect { |f| "<option value=#{f.inspect}>#{f}</option>" } %>
            </select> 
            <br/>
            <input type="search" id="search-text" name="q" value=" " /> <br />
            <input type="submit" value="Search" />
          </form>
        </li>
      
      
      <div id="footer">&nbsp;</div>
    </div>
  </body>
</html>
