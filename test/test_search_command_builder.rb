require "test/unit"


class TestSearchCommandBuilder < Test::Unit::TestCase
  
  def setup
    @params = { 'q' => "Processing", 'file' => 'logfile.log', 'shop' => 'myshop' }
  end
  
  def test_build_command_with_query_and_file_and_shop
    query = SearchCommandBuilder.build_command(@params)
    assert_equal "sh -c 'grep -A4 -B4 -e myshop logfile.log | grep -A4 -B4 -e Processing'", query
  end
  
  def test_build_command_with_no_shop
    query = SearchCommandBuilder.build_command(@params.delete('shop'))
    assert_equal "sh -c 'grep -A4 -B4 -e Processing logfile.log'", query    
  end
  
end