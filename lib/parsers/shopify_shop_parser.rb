class ShopifyShopParser
    
  LineRegexp   = /^\[([a-zA-Z0-9\-.]+)\]\s*(.*)/
  
  attr_accessor :elements
  
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
      if results[1] =~ /\./
        @elements[:shop] = results[1]
        @elements[:line] = results[-1]
        results[-1]
      else
        @elements[:line] = line
        line
      end
    else
      line
    end
  end
end