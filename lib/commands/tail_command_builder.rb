# 
# Handles tailing of log files
#
class TailCommandBuilder < CommandBuilder
  
  def valid?
    raise InvalidParameterError, "Log file parameter not supplied or invalid log file" unless filename && !filename.empty? && File.extname(filename) == ".log"
    true
  end
  
    def command
    results = []
    exec_functions.each_with_index do |cmd, index|
      if index == 0
        results << cmd.gsub('filename', filename.to_s)
      else
        results << cmd.gsub('filename', filename.to_s).gsub('options', options.to_s).gsub('term', terms[index-1].to_s)
      end
    end
    %[sh -c '#{results.join(" | ")}']
  end

  
  def default_tools
    terms.empty? ? ['tail -n 250 -f filename'] : ['tail -n 250 -f filename'] + ['grep options -e term'] * (terms.size)
  end
end