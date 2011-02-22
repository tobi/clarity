class GrepCommandBuilder

  # parameter names
  TermParameters = ['term1', 'term2', 'term3']
  FileParameter  = 'file'

  attr_accessor :params
  attr_reader   :terms, :filename, :options

  def initialize(params)
    @params   = params
    @filename = params.fetch(FileParameter)
    @terms    = TermParameters.map {|term| params.fetch(term, nil) }.compact.reject {|term| term.empty? }
    @options  = ""
    valid?
  end

  def valid?
    raise InvalidParameterError, "Log file parameter not supplied" unless filename && !filename.empty?
    true
  end
  
  def command
    results = []
    exec_functions.each_with_index do |cmd, index|
      results << cmd.gsub('filename', filename.to_s).gsub('options', options.to_s).gsub('term', terms[index].to_s)
    end
    %[sh -c '#{results.join(" | ")}']
  end


  def exec_functions
    type = `file #{filename}`
    if type.include?("gzip")
      gzip_tools
    elsif type.include?("bzip2")
      bzip_tools
    else
      default_tools
    end
  end

  
  def gzip_tools
    cat_tool = (ENV["PATH"].split(":").find{|d| File.exists?(File.join(d, "gzcat"))} ? "zcat" : "gzcat")
    terms.empty? ? ["#{cat_tool} filename"] : ['zgrep options -e term filename'] + ['grep options -e term'] * (terms.size-1)
  end  
  
  def bzip_tools
    terms.empty? ? ['bzcat filename'] : ['bzgrep options -e term filename'] + ['grep options -e term'] * (terms.size-1)
  end
  
  def default_tools
    terms.empty? ? ['cat filename'] : ['grep options -e term filename'] + ['grep options -e term']* (terms.size-1)
  end


  class InvalidParameterError < StandardError; end
  
end