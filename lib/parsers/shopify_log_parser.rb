
class ShopifyLogParser

  # sample log output
  # Jul 24 14:58:21 app3 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 
  # 1 date
  # 2 app
  # 3 shop
  # 4 line
  LineRegexp   = /^(\w+\s+\d+\s\d\d:\d\d:\d\d)\s(\w+)\s([^:]*):\s\[([^\]]+)\]\s*(.*)/
  
  def initialize(next_renderer = nil)
    @next_renderer = next_renderer
  end
  
  def parse(line, elements = {})
    @elements = elements
    # parse line into elements and put into element
    next_line = parse_line(line)
    if @next_renderer && next_line
      @elements = @next_renderer.parse(next_line, @elements)
    else
      @elements
    end
  end
  
  # parse line and break into pieces
  def parse_line(line)
    results = LineRegexp.match(line)
    if results 
      @elements[:timestamp] = results[1]
      @elements[:shop]      = results[4]
      @elements[:line]      = results[-1]
      results[-1] # remaining line      
    else
      nil # nothing parsed
    end
  end
end