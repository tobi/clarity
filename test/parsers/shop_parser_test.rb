require 'test_helper'

class ShopParserTest < Test::Unit::TestCase
  
  def setup
    @parser = ShopParser.new(nil)
    @lines = %|[wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]
 [wadedemt.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]
[test.myshopify.com]   Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]
[my-shop.myshopify.com]   Processing some other line of text
Jul  7 20:12:11 staging rails.shopify[27975]: [jessetesting.staging.shopify.com]   Processing Admin::ProductsController#index (for 67.70.29.242 at 2009-07-07 20:12:11) [GET]
|.split("\n")
  end
  
  def test_parse_shop_name
    line = @lines.first
    out  = @parser.parse(line)
    
    assert out.has_key?(:shop)
    assert out.has_key?(:line)
    assert_equal "wadedemt.myshopify.com", out[:shop]
    assert_equal "Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]", out[:line]
  end
  
  def test_parse_shop_name_with_extra_space
    line = @lines[1]
    out  = @parser.parse(line)
    
    assert out.has_key?(:shop)
    assert out.has_key?(:line)
    assert_equal "wadedemt.myshopify.com", out[:shop]
    assert_equal "Processing ShopController#products (for 192.168.1.230 at 2009-07-24 14:58:21) [GET]", out[:line]    
  end
  
  def test_parse_shop_name_with_dashes
    line = @lines[3]
    out  = @parser.parse(line)
    
    assert out.has_key?(:shop)
    assert out.has_key?(:line)
    assert_equal "my-shop.myshopify.com", out[:shop]
    assert_equal "Processing some other line of text", out[:line]        
  end
  
  def test_parse_with_no_shop_returns_line
    line = @lines[4]
    out  = @parser.parse(line)
    assert !out.has_key?(:shop)
    assert_equal line, out[:line]
  end
  
end
  