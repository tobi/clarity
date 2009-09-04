require 'action_view'
require 'uri'

class ShopifyLogRenderer
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  
  Prefix   = ""
  Suffix   = "<br/>\n"
  TagOrder = [ :timestamp, :shop, :labels, :line  ]
  MarkTime = 60 * 5 # 5 minutes

  def initialize()
    @last_timestamp = nil
  end
  
  def render(elements = {})
    @elements = elements
    @tags = []
    TagOrder.each do |tag|
      content = @elements.fetch(tag, nil)
      next if content.nil?
      method  = ("buildtag_"+tag.to_s).to_sym
      @tags << self.send(method, content)
    end
    
    if !@tags.empty?
      Prefix + @tags.join(" ").to_s + Suffix
    else
      ""
    end
  end
  
    
  def buildtag_timestamp(content, options = {})
    content + " : "
  end
  
  def buildtag_line(content, options = {})
    ERB::Util.h(content) #.gsub(/\n/, '<br/>')
  end
  
  def buildtag_shop(content, options = {})
    "[<a href='http://#{URI.escape(content)}'>#{content}</a>]"
  end
  
  def buildtag_labels(content, options = {})
    "[#{content}]"
  end

end