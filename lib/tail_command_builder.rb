# 
# Handles tailing of log files
#
class TailCommandBuilder < CommandBuilder
  
  def self.build_command(params)
    validate_params(params)
    
    tool    = 'tail'
    file    = get_file(params)
    terms   = get_search_terms(params)
    options = "-n 250 -f"
    
    # build search fragments
    fragments = []
    # first filter
    fragments << first_filter(tool, file, nil, options)
    # remaining filters
    terms.each do |term|
      fragments << next_filter('grep', file, term, options)
    end

    %[sh -c '#{fragments.join(" | ")}']
  end

  # tail
  def self.first_filter(tool, file, term, options = "")
    "#{tool} #{options} #{file}"
  end
  
  # grep filtering
  def self.next_filter(tool, file, term, options = "")
    "#{tool} -e #{term}"
  end
  
  
  def self.validate_params(params)
    super
  end  
end