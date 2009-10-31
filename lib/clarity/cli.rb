require 'optparse'
#require File.dirname(__FILE__) + '/../clarity'

module GrepRenderer  
  attr_accessor :response, :parser, :marker, :params

  def parser
    @parser ||= TimeParser.new( HostnameParser.new(ShopParser.new), params)
  end

  def renderer
    @renderer ||= LogRenderer.new
  end

  # once download is complete, send it to client
  def receive_data(data)
    @buffer ||= StringScanner.new("")
    @buffer << data

    html = ""
    while line = @buffer.scan_until(/\n/)
      tokens = parser.parse(line)
      html << renderer.render(tokens)
    end

    return if html.empty?

    response.chunk html
    response.send_chunks
  end

  def unbind
    response.chunk '</div><hr><p id="done">Done</p></body></html>'
    response.chunk ''
    response.send_chunks
    puts 'Done'
  end
end




module Clarity
  class CLI
    def self.execute(stdout, arguments=[])
      
      options = {
        :username => nil,
        :password => nil,
        :log_files => ['**/*.log*'],
        :port => 8080,
        :address => "0.0.0.0"
      }
      
      mandatory_options = %w(  )
      
      ARGV.options do |opts|
        opts.banner = "Usage:  #{File.basename($PROGRAM_NAME)} [options] directory"

        opts.separator " "
        opts.separator "Specific options:"

        opts.on( "-f", "--config=FILE", String, "Config file (yml)" ) do |opt|
          options.update YAML.load_file( opt )
        end

        opts.on( "-p", "--port=PORT", Integer, "Port to listen on" ) do |opt|
          options[:port] = opt
        end  

        opts.on( "-b", "--address=ADDRESS", String, "Address to bind to (default 0.0.0.0)" ) do |opt|
          options[:address] = opt
        end  

        opts.on( "--include=MASK", String, "File mask of logs to add (default: **/*.log*)" ) do |opt|
          options[:log_files] ||= []
          options[:log_files] += opt
        end

        opts.separator " "
        opts.separator "Password protection:"

        opts.on( "--username=USER", String, "Enable httpauth username" ) do |opt|
          options[:username] = opt
        end

        opts.on( "--password=PASS", String, "Enable httpauth password" ) do |opt|
          options[:password] = opt
        end

        opts.separator " "
        opts.separator "Misc:"

        opts.on( "-h", "--help", "Show this message." ) do
          puts opts
          exit
        end

        opts.separator " "

        begin
          opts.parse!(arguments)
          
          if arguments.first
            Dir.chdir(arguments.first)
          end
          
          ::Clarity::Server.run(options)
          
        #rescue
        #  puts opts
        #  exit
        end
      end
            
    end
  end
end