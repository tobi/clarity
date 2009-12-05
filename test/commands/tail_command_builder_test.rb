require 'test_helper'

class TailCommandBuilderTest < Test::Unit::TestCase
  
  def setup
    @params = { 
      "file" => "testfile.log", 
      "tool" => "tail",
      "term1" => "foo",
      "term2" => nil,
      "term3" => nil
    }
    @command = TailCommandBuilder.new(@params)
  end
  
  def test_create_new_builder
    assert @command.is_a?(TailCommandBuilder)
    assert_equal "testfile.log", @command.filename
    assert_equal 1, @command.terms.size
  end
  
  def test_raises_error_if_invalid_file
    assert_raises GrepCommandBuilder::InvalidParameterError do
      command = TailCommandBuilder.new(@params.merge("file" => "testfile.gz"))
    end
  end
  
  def test_command_for_log
    command = TailCommandBuilder.new(@params)
    assert_equal "sh -c 'tail -n 250 -f testfile.log | grep  -e foo'", command.command
  end

  def test_command_with_no_terms_for_log
    command = TailCommandBuilder.new(@params.merge("term1" => nil))
    assert_equal "sh -c 'tail -n 250 -f testfile.log'", command.command    
  end
  
  def test_command_with_multiple_terms_for_log
    command = TailCommandBuilder.new(@params.merge("term2" => "bar", "term3" => "baz"))
    assert_equal "sh -c 'tail -n 250 -f testfile.log | grep  -e foo | grep  -e bar | grep  -e baz'", command.command
  end
end