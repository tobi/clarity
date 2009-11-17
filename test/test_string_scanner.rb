require 'test_helper'
require "strscan"

class TestLibraryFileName < Test::Unit::TestCase
  
  NewLine = /\n/
  def test_case_name
    s = StringScanner.new('')
    s << "abc\nd"
    assert_equal "abc\n", s.scan_until(NewLine)
    assert_equal nil, s.scan_until(NewLine)
    s << "ef\ng"
    assert_equal "def\n", s.scan_until(NewLine)
    assert_equal nil, s.scan_until(NewLine)    
  end
end