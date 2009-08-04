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
    # time = Time.parse(content)
    # if @last_timestamp.nil? || (@last_timestamp + MarkTime) < time
    #   @last_timestamp = time
    #   content
    #   #content_tag(:p, content, :class => "time")
    # end
  end
  
  def buildtag_line(content, options = {})
    #content_tag(:p, ERB::Util.h(content).gsub(/\n/, '<br/>'), :title => @elements[:timestamp])
    ERB::Util.h(content) #.gsub(/\n/, '<br/>')
  end
  
  def buildtag_shop(content, options = {})
    url = "https://app.shopify.com/services/internal/shops/show"
    #content_tag(:span, link_to(content, "#{url}?find=#{URI.escape(content)}", :class => 'shop'), :class => 'label')
    "[<a href='#{url}?find=#{URI.escape(content)}'>#{content}</a>]"
  end
  
  def buildtag_labels(content, options = {})
    #content_tag(:span, content, :class => 'label')
    "[#{content}]"
  end

end