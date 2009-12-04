module Clarity
  module GrepRenderer
    attr_accessor :response
    attr_writer :renderer

    def renderer
      @renderer ||= LogRenderer.new
    end

    # once download is complete, send it to client
    def receive_data(data)
      @buffer ||= StringScanner.new("")
      @buffer << data

      while line = @buffer.scan_until(/\n/)
        response.chunk renderer.render(line)
        flush
      end      
    end
            
    def flush
      response.send_chunks
    end
    
    def close
      ProcessTree.kill(get_status.pid)      
    end    

    def unbind          
      response.chunk renderer.finalize
      response.chunk ''
      close
      flush
      puts 'Done'
    end
  end
end
