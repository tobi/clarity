require "test/unit"
require File.dirname(__FILE__) + "/../../lib/parsers/hostname_parser.rb"

class HostnameParserTest < Test::Unit::TestCase
  
  def setup
    @params = { "sh" => "12", "sm" => "00", "ss" => "10", "eh" => "12", "em" => "00", "es" => "59" }    
    @lines = %|Jul 24 14:58:21 app3 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]
Jul 24 12:00:21 192.168.5.1 rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]
Jul 24 12:00:31 192.168.5.1 rails.shopify[9855]: [test.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]
Jul 24 12:00:41 192.168.5.1 rails.shopify[9855]: [test2.myshopify.com]   Processing some other line of text 
|.split("\n")
    @parser = HostnameParser.new(nil)
  end
  
  
  def test_parse_strips_out_ip_and_appname
    line = @lines[1][16..-1] # strip out first 16 lines
    out = @parser.parse(line)
    
    assert out.has_key?(:line)
    assert_equal "[wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]", out[:line]
  end
  
  def test_parse_strips_out_host_and_appname
    line = @lines.first[16..-1] # strip out first 16 lines
    out = @parser.parse(line)
    
    assert out.has_key?(:line)
    assert_equal "[wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]", out[:line]    
  end
  
  def test_parse_returns_line_if_no_match
    line = "in@valid rails.shopify[9855]: [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]"
    out = @parser.parse(line)
    assert out.has_key?(:line)
    assert_equal line, out[:line]
  end
  
end