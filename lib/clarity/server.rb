require 'cgi'
require File.dirname(__FILE__) + '/server/basic_auth'
require File.dirname(__FILE__) + '/server/mime_types'
require File.dirname(__FILE__) + '/server/chunk_http'
require File.dirname(__FILE__) + '/grep_renderer'

module Clarity
  class NotFoundError < StandardError; end
  class NotAuthenticatedError < StandardError; end
  class InvalidParameterError < StandardError; end

  module Server
    include EventMachine::HttpServer
    include Clarity::BasicAuth
    include Clarity::ChunkHttp
    
    attr_accessor :required_username, :required_password
    attr_accessor :log_files    
    
    def self.run(options)
      EventMachine::run do
        EventMachine.epoll
        EventMachine::start_server(options[:address], options[:port], self) do |a|
          a.log_files = options[:log_files]
          a.required_username = options[:username]
          a.required_password = options[:password]
        end
        STDERR.puts "Listening #{options[:address]}:#{options[:port]}..."
        STDERR.puts "Adding log files: #{options[:log_files].inspect}"
      end      
    end

    def process_http_request    
      authenticate!

      puts "action: #{path}"
      puts "params: #{params.inspect}"

      case path
      when '/'
        respond_with(200, welcome_page)

      when '/perform'
        if params.empty?
          respond_with(200, welcome_page)
        else
          # get command
          command = case params['tool']
            when 'grep' then CommandBuilder.new(params).command
            when 'tail' then TailCommandBuilder.new(params).command
            else raise InvalidParameterError, "Invalid Tool parameter"
          end
          response = respond_with_chunks
          response.chunk results_page # display page header

          puts "Running: #{command}"
          EventMachine::popen(command, GrepRenderer) do |grepper|
            @grepper = grepper          
            @grepper.marker = 0
            @grepper.params = params
            @grepper.response = response 
          end
        end

      when '/test'
        response = init_chunk_response
        EventMachine::add_periodic_timer(1) do 
          response.chunk "Lorem ipsum dolor sit amet<br/>"        
          response.send_chunks
        end

      else                          
        respond_with(200, public_file(path), :content_type => Mime.for(path))
      end

    rescue InvalidParameterError => e
      respond_with(500, error_page(e))
    rescue NotFoundError => e
      respond_with(404, "<h1>Not Found</h1>")
    rescue NotAuthenticatedError => e
      puts "Could not authenticate user"
      headers = { "WWW-Authenticate" => %(Basic realm="Clarity")}
      respond_with(401, "HTTP Basic: Access denied.\n", :content_type => 'text/plain', :headers => headers)
    end    
    
    def error_page(error)
      @error = error
      render "error.html.erb"
    end

    def welcome_page
      render "index.html.erb"
    end

    def results_page
      render "index.html.erb"
    end

    def unbind
      return unless @grepper
      kill_processes(@grepper.get_status.pid)
      close_connection
    end

    def kill_processes(ppid)
      return if ppid.nil?
      all_pids = [ppid] + get_child_pids(ppid).flatten.uniq.compact
      puts "=== pids are #{all_pids.inspect}"
      all_pids.each do |pid|
        Process.kill('TERM',pid.to_i)
        puts "=== killing #{pid}"
      end
    rescue Exception => e
      puts "!Error killing processes: #{e}"
    end

    def get_child_pids(ppid)
      out = `ps -opid,ppid | grep #{ppid.to_s}`
      ids = out.split("\n").map {|line| $1 if line =~ /^\s*([0-9]+)\s.*/ }.compact
      ids.delete(ppid.to_s)
      if ids.empty?
        ids
      else
        ids << ids.map {|id| get_child_pids(id) }
      end
    end

    private

    def authenticate!
      login, pass = authentication_data

      if (required_username && required_username != login) || (required_password && required_password != pass)    
        raise NotAuthenticatedError
      end

      true
    end

  end


end