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
    @tags = []
    @last_timestamp = nil
  end
  
  def render(elements)
    @elements = elements
    TagOrder.each do |tag|
      content = @elements.fetch(tag, nil)
      next if content.nil?
      method  = ("build_tag_"+tag.to_s).to_sym
      @tags << self.send(method, content)
    end
    Prefix + @tags.join.to_s + Suffix
  end
  
    
  def build_tag_timestamp(content, options = {})
    time = Time.parse(content)
    if @last_timestamp.nil? || (@last_timestamp + MarkTime) < time
      @last_timestamp = time
      content_tag(:p, content, :class => "time")
    end
  end
  
  def build_tag_line(content, options = {})
    content_tag(:p, content, :title => @elements[:timestamp])
  end
  
  def build_tag_shop(content, options = {})
    url = "https://app.shopify.com/services/internal/shops/show"
    content_tag(:span, link_to(content, "#{url}?find=#{URI.escape(content)}", :class => 'shop'), :class => 'label')
  end
  
  def build_tag_labels(content, options = {})
    content_tag(:span, content, :class => 'label')
  end
  

  
  #     @tags     = []
  #   TagOrder.each do |tag_type|
  #     content = @elements.fetch(tag_type, nil)
  #     next if content.nil?
  #     method  = ("build_tag_"+tag_type.to_s).to_sym
  #     @tags << self.send(method, content)
  #   end
  #     
  #   # render html tags
  #   Prefix + @tags.join.to_s + Suffix
  # end

  
end