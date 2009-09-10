
class HostnameParser

  # given a string in format:
  #
  # app3 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 
  # 129.123.2.1 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 
  #
  # strips out the hostname/IP and appname
  #
  # result => [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 
  
  
  LineRegexp   = /^([\w-]+|\d+\.\d+\.\d+\.\d+)\s([^:]*):\s*(.*)/
  
  attr_accessor :elements, :next_parser
  
  def initialize(next_renderer = nil)
    @next_renderer = next_renderer
  end
  
  def parse(line, elements = {})
    @elements = elements
    # parse line into elements and put into element
    next_line = parse_line(line)
    if @next_renderer && next_line
      @elements = @next_renderer.parse(next_line, @elements)
    end
    @elements
  end
  
  # parse line and break into pieces
  def parse_line(line)
    results = LineRegexp.match(line)
    if results 
      @elements[:line] = results[-1]
      results[-1] # remaining line      
    else
      @elements[:line] = line
      line      
    end
  end
end