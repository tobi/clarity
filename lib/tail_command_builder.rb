# 
# Handles tailing of log files
#
class TailCommandBuilder < CommandBuilder
  
  def self.build_command(params)
    validate_params(params)
    tool    = 'tail'
    queries = get_queries(params)
    file    = params['file']
    options = "-n 250 -f"
    
    fragments = []
    fragments << first_filter(tool, file, options)
    fragments << next_filter('grep', queries.shift, file, options) unless queries.empty?
    fragments << next_filter('grep', queries.shift, file, options) unless queries.empty?
    %[sh -c '#{fragments.join(" | ")}']
  end

  def self.first_filter(tool, file, options)
    "#{tool} #{options} #{file}"
  end
  
  def self.next_filter(tool, query, file, options)
    "#{tool} -e #{query}"
  end
  
  private
  
  def self.validate_params(params)
    raise InvalidParameterError, "Shop url cannot be blank" if params['shop'].nil? || params['shop'].blank?
  end
  
  def self.get_queries(params)
    results = []
    results << sanitize_query(params['shop']) if params['shop']
    results << sanitize_query(params['q']) if params['q']
    results.compact
  end
  
end