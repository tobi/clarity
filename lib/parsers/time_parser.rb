
class TimeParser

  # sample log output
  # Jul 24 14:58:21 app3 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 
  # 1 date
  # 2 app
  # 3 shop
  # 4 line
  LineRegexp   = /^(\w+\s+\d+\s\d\d:\d\d:\d\d)\s(.*)/
  
  OFFSET = 4 * 60 * 60 # est offset
  
  attr_accessor :elements, :params
  
  def initialize(next_renderer = nil, params = {})
    @next_renderer = next_renderer
    @params = params
  end
  
  def parse(line, elements = {})
    @elements = elements
    # parse line into elements and put into element
    next_line = parse_line(line)
    if @next_renderer && next_line
      if !start_time_valid? || !end_time_valid?
        @elements = {}  # empty tag
      else
        @elements = @next_renderer.parse(next_line, @elements)
      end
    end
    @elements
  end

  # check if current line's time is >= start time, if it was set
  def start_time_valid?
    return true if params['sh'].blank? # return true if filter not set
    
    line_time = Time.parse(@elements[:timestamp]) # assume we are in UTC
    start_time = Time.utc(line_time.year, line_time.month, line_time.day, params.fetch('sh',0).to_i, params.fetch('sm', 0).to_i, params.fetch('ss', 0).to_i )    
    line_time >= start_time ? true : false
  rescue Exception => e
    puts "Error! #{e}"
  end

  def end_time_valid?
    return true if params['eh'].blank? # return true if filter not set
    
    line_time = Time.parse(@elements[:timestamp]) # assume we are in UTC
    end_time = Time.utc(line_time.year, line_time.month, line_time.day, params.fetch('eh',0).to_i, params.fetch('em', 0).to_i, params.fetch('es', 0).to_i )
    line_time <= end_time ? true : false
  rescue Exception => e
    puts "Error! #{e}"
  end

  
  # parse line and break into pieces
  def parse_line(line)
    results = LineRegexp.match(line)
    if results 
      @elements[:timestamp] = results[1]
      @elements[:line]      = results[-1]
      results[-1] # remaining line      
    else
      @elements[:line] = line
      line      
    end
  end  
  
end