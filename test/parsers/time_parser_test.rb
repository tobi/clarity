require 'test_helper'

class TimeParserTest < Test::Unit::TestCase
  
  def setup
    @params = { "sh" => "12", "sm" => "00", "ss" => "10", "eh" => "12", "em" => "00", "es" => "59" }    
    @lines = %|Jul 24 14:58:21 app3 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]
Jul 24 12:00:21 192.168.5.1 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 
Jul 24 12:00:31 192.168.5.1 rails.shopify[9855]: [test.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] 
Jul 24 12:00:41 192.168.5.1 rails.shopify[9855]: [test2.myshopify.com]   Processing some other line of text 
|.split("\n")
  end
  
  def test_parse_timestamp
    @parser = TimeParser.new(nil, {})
    line = @lines.first
    elements = @parser.parse(line)
    
    assert elements.has_key?(:timestamp)
    assert_equal "Jul 24 14:58:21", elements[:timestamp]
    assert_equal "app3 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]", elements[:line]
  end
  
  def test_parse_with_start_time_and_early_timestamp
    @parser = TimeParser.new(nil, {"sh" => "15", "sm" => "00", "ss" => "10"})
    line = @lines.first
    elements = @parser.parse(line)

    # does not match - reject line all together
    assert elements.empty?    
  end
  
  def test_parse_with_start_time_and_later_timestamp
    @parser = TimeParser.new(nil, {"sh" => "12", "sm" => "00", "ss" => "10"})
    line = @lines[1]
    elements = @parser.parse(line)
    
    assert elements.has_key?(:timestamp)
    assert elements.has_key?(:line)    
  end

  def test_parse_with_end_time_and_early_timestamp
    @parser = TimeParser.new(nil, {"eh" => "12", "em" => "00", "es" => "00"})
    line = @lines.first
    elements = @parser.parse(line)
    
    assert elements.empty?    
  end
  
  def test_parse_with_end_time_and_later_timestamp
    @parser = TimeParser.new(nil, {"eh" => "13", "em" => "00", "es" => "00"})
    line = @lines[1]
    elements = @parser.parse(line)
    
    assert elements.has_key?(:timestamp)
    assert elements.has_key?(:line)    
  end
  
  def test_parse_with_entry_between_start_and_end
    @parser = TimeParser.new(nil, {"sh" => "14", "sm" => "00", "ss" => "00", "eh" => "15", "em" => "00", "es" => "00"})
    line = @lines.first
    elements = @parser.parse(line)
    
    assert elements.has_key?(:timestamp)
    assert elements.has_key?(:line)    
  end
  
  def test_parse_with_entry_outside_start_and_end
    @parser = TimeParser.new(nil, {"sh" => "14", "sm" => "00", "ss" => "00", "eh" => "15", "em" => "00", "es" => "00"})
    line = @lines[1]
    elements = @parser.parse(line)
    
    assert elements.empty?    
  end
  
  def test_parse_returns_entry_if_doesnt_match_parser
    line = "July 24, 1999 12:00:21 192.168.5.1 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET] "
    @parser = TimeParser.new(nil)
    elements = @parser.parse(line)
    assert_equal line, elements[:line]
  end
  
end