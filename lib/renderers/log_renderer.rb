require 'action_view'
require 'uri'

class LogRenderer
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  
  Prefix   = ""
  Suffix   = "<br/>\n"
  TagOrder = [ :timestamp, :shop, :labels, :line ]
  MarkTime = 60 * 5 # 5 minutes

  def initialize()
    @last_timestamp = nil
  end
  
  def render(elements = {})
    @elements = elements
    @tags = []
    TagOrder.each do |tag|
      if content = @elements.fetch(tag, nil)
        method  = ("tag_"+tag.to_s).to_sym
        @tags << self.send(method, content)
      end
    end
    
    @tags.empty? ? "" : Prefix + @tags.join(" ").to_s + Suffix
  end
  
    
  def tag_timestamp(content, options = {})
    content + " : "
  end
  
  def tag_line(content, options = {})
    ERB::Util.h(content)
  end
  
  def tag_shop(content, options = {})
    "[<a href='http://#{URI.escape(content)}'>#{content}</a>]"
  end
  
  def tag_labels(content, options = {})
    "[#{content}]"
  end

end