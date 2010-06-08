require 'uri'
require 'erb'

class LogRenderer  
  
  # Thank you to http://daringfireball.net/2009/11/liberal_regex_for_matching_urls
  #
  UrlParser = %r{\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))}

  IpParser = %r{\b(\d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3})}
  DateParser = %r{\[(\d{2}\/\w{3}\/\d{4}\:\d{2}\:\d{2}\:\d{2}\s\+\d{4})\]|^(\w{3}\s\d{2}\s\d{2}:\d{2}:\d{2})}
  BrowserDetails = %r{;\s&quot;(.+)&quot;$}
  EOLStatus = %r{\(.+\)\s?$}
  HttpVerbs = %r{(GET|POST|PUT|DELETE|HEAD)}
  Email = %r{(\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b)}
  Emailstatus = %r{(status=\w+)}
  KeyValue = %r(&quot;\w+&quot;=&gt;(?:&quot;[^&]+?&quot;|[0-9\.]+|true|false|nil|[A-Z].+?\s\d{4})(?:,|}))

  Prefix   = ""
  Suffix   = "<br/>\n"
  
  def render(line = {})
    # Escape
    output = ERB::Util.h(line)
    
    # Transform urls into html links
    output.gsub!(UrlParser) do |match|
      html_link(match)
    end
    
    # Catch for key and value
    output.gsub!(KeyValue) do |match|
      (key, value) = match.split("=&gt;")
      "<span class=\"keys\">#{key}</span>=&gt;<span class=\"values\">#{value}</span>"
    end 
    # Formats IPs
    output.gsub!(IpParser) do |match|
      "<span class=\"ipaddress\">#{match}</span>"
    end 

    # Format Standard unix log types formats
    output.gsub!(DateParser) do |match|
      "<span class=\"date\">#{match}</span>"
    end
    # Format end of line status messages in mail.log
    output.gsub!(EOLStatus) do |match|
      "<span class=\"eolstatus\">#{match}</span>"
    end 

    # Format Apache Browser Specifics
    output.gsub!(BrowserDetails) do |match|
      "<span class=\"browser\">#{match}</span>"
    end
   
    # Format HTTP Verbs
    output.gsub!(HttpVerbs) do |match|
      "<span class=\"httpverbs\">#{match}</span>"
    end

    # Format Email addresses
    output.gsub!(Email) do |match|
      "<span class=\"email\">#{match}</span>"
    end
    
    # Format Email status messages
    output.gsub!(Emailstatus) do |match|
      "<span class=\"emailstatus\">#{match}</span>"
    end

    # Return with formatting
    "#{Prefix}#{output}#{Suffix}"
  end
  
  def finalize
    '</div><hr><p id="done">Done</p></body></html>'
  end
  
  private
    
  def html_link(url)
    uri = URI.parse(url) rescue url
    "<a href='#{uri}'>#{url}</a>"
  end
end 
