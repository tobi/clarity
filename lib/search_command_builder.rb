class SearchCommandBuilder < CommandBuilder
  
  def self.build_command(params)
    validate_params(params)

    file    = get_file(params)
    tool    = get_tool(params)
    terms   = get_search_terms(params)
    options = ""
    
    puts "file: #{file} tool #{tool} terms: #{terms.inspect}"
    # build search fragments
    fragments = []
    # first filter
    fragments << first_filter(tool, file, terms.shift, options)
    # remaining filters
    terms.each do |term|
      fragments << next_filter('grep', file, term, options)
    end
    
    %[sh -c '#{fragments.join(" | ")}']    
  end

  def self.first_filter(tool, file, term, options = "")
    "#{tool} #{options} -e #{term} #{file}"
  end
  
  def self.next_filter(tool, file, term, options = "")
    "#{tool} #{options} -e #{term}"
  end


  def self.validate_params(params)
    super
  end
  
  def self.get_tool(params)
    case
      when params['file'].include?('.gz') 
        'zgrep'
      when params['file'].include?('.bz2')
        'bzgrep'
      else 
        'grep'
    end
  end
  
end