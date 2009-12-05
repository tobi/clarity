require 'test_helper'

class GrepCommandBuilderTest < Test::Unit::TestCase
  
  def setup
    @params = { 
      "file" => "testfile.log", 
      "tool" => "grep",
      "term1" => "foo",
      "term2" => nil,
      "term3" => nil
    }
    @command = GrepCommandBuilder.new(@params)
  end
  
  def test_create_new_builder
    assert @command.is_a?(GrepCommandBuilder)
    assert_equal "testfile.log", @command.filename
    assert_equal 1, @command.terms.size
  end
  
  def test_raises_error_if_no_file
    assert_raises GrepCommandBuilder::InvalidParameterError do
      command = GrepCommandBuilder.new(@params.merge("file" => nil))
    end
  end
  
  def test_exec_functions_for_log
    command = GrepCommandBuilder.new(@params)
    assert_equal 1, command.exec_functions.size
    assert_match(/^grep/, command.exec_functions.first)
  end
  
  def test_exec_functions_with_multiple_terms_for_log
    command = GrepCommandBuilder.new(@params.merge("term2" => "bar", "term3" => "baz"))
    assert_equal 3, command.exec_functions.size
    assert_match(/^grep/, command.exec_functions[0])
    assert_match(/^grep/, command.exec_functions[1])
    assert_match(/^grep/, command.exec_functions[2])    
  end
  
  def test_exec_function_with_no_terms_for_log
    command = GrepCommandBuilder.new(@params.merge("term1" => nil))
    assert_equal 1, command.exec_functions.size
    assert_match(/^cat/, command.exec_functions[0])
  end

  def test_exec_funcations_for_gzip
    command = GrepCommandBuilder.new(@params.merge("file" => "testfile.gz"))
    assert_equal 1, command.exec_functions.size
    assert_match(/^zgrep/, command.exec_functions.first)
  end
    
  def test_exec_functions_with_multiple_terms_for_gzip
    command = GrepCommandBuilder.new(@params.merge("file" => "testfile.gz", "term2" => "bar", "term3" => "baz"))
    assert_equal 3, command.exec_functions.size
    assert_match(/^zgrep/, command.exec_functions[0])
    assert_match(/^grep/, command.exec_functions[1])
    assert_match(/^grep/, command.exec_functions[2])
  end
  
  def test_exec_function_with_no_terms_for_gzip
    command = GrepCommandBuilder.new(@params.merge("file" => "testfile.gz", "term1" => nil))
    assert_equal 1, command.exec_functions.size
    assert_match "gzcat", command.exec_functions[0]
  end

  def test_command_for_log
    command = GrepCommandBuilder.new(@params)
    assert_equal "sh -c 'grep  -e foo testfile.log'", command.command
  end

  def test_command_with_no_terms_for_log
    command = GrepCommandBuilder.new(@params.merge("term1" => nil))
    assert_equal "sh -c 'cat testfile.log'", command.command    
  end
  
  def test_command_with_multiple_terms_for_log
    command = GrepCommandBuilder.new(@params.merge("term2" => "bar", "term3" => "baz"))
    assert_equal "sh -c 'grep  -e foo testfile.log | grep  -e bar | grep  -e baz'", command.command
  end

  def test_command_for_gzip
    command = GrepCommandBuilder.new(@params.merge("file" => "testfile.gz"))
    assert_equal "sh -c 'zgrep  -e foo testfile.gz'", command.command
  end

  def test_command_with_no_terms_for_gzip
    command = GrepCommandBuilder.new(@params.merge("file" => "testfile.gz","term1" => nil))
    assert_equal "sh -c 'gzcat testfile.gz'", command.command    
  end
  
  def test_command_with_multiple_terms_for_gzip
    command = GrepCommandBuilder.new(@params.merge("file" => "testfile.gz","term2" => "bar", "term3" => "baz"))
    assert_equal "sh -c 'zgrep  -e foo testfile.gz | grep  -e bar | grep  -e baz'", command.command
  end


end