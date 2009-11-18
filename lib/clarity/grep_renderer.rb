module Clarity
  module GrepRenderer
    attr_accessor :marker, :params, :response
    attr_writer :parser, :renderer

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
end
