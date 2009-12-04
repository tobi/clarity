require 'uri'
require 'erb'

class LogRenderer  
  
  # Thank you to http://daringfireball.net/2009/11/liberal_regex_for_matching_urls
  #
  UrlParser = %r{\b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))}
  Prefix   = ""
  Suffix   = "<br/>\n"
  
  def render(line = {})
    # Escape
    output = ERB::Util.h(line)
    
    # Transform urls into html links
    output.gsub!(UrlParser) do |match|
      html_link(match)
    end
        
    # Return with formatting
    "#{Prefix}#{output}#{Suffix}"
  end
  
  def finalize
    '</div><hr><p id="done">Done</p></body></html>'
  end
  
  private
    
  def html_link(url)
    uri = URI.parse(url)
    "<a href='#{uri}'>#{url}</a>"
  end
  
end