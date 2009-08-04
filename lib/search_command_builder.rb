class SearchCommandBuilder < CommandBuilder
  
  def self.build_command(params)
    validate_params(params)
    tool    = get_tool(params)
    queries = get_queries(params)
    file    = params['file']
    #options = "-A4 -B4"
    options = ""
    
    fragments = []
    fragments << first_filter(tool, queries.shift, file, options)
    fragments << next_filter('grep', queries.shift, file, options) unless queries.empty?
    %[sh -c '#{fragments.join(" | ")}']
  end

  def self.first_filter(tool, query, file, options)
    "#{tool} #{options} -e #{query} #{file}"
  end
  
  def self.next_filter(tool, query, file, options)
    "#{tool} #{options} -e #{query}"
  end
  
  private
  
  def self.validate_params(params)
    raise InvalidParameterError, "Query cannot be blank" if params['q'].nil? || params['q'].blank?
  end
  
  def self.get_queries(params)
    results = []
    if params['shop']
      results << sanitize_query(params['shop'])
    end
    results << sanitize_query(params['q'])
    results.compact
  end
  
  def self.get_tool(params)
    tool = case
      when params['file'].include?('.gz') then 'zgrep'
      when params['file'].include?('.bz2') then 'bzgrep'
      else 'grep'
    end
    tool
  end
end