autoload(:CGI, 'cgi') # in case you want to use html_unescape

module Innate

  # Shortcuts to some CGI methods

  module Helper
    module CGI
      module_function

      # Shortcut for Rack::Utils.escape
      #
      # @param [#to_s] input
      # @return [String] URI-encoded representation of +input+
      def url_encode(input)
        Rack::Utils.escape(input.to_s)
      end
      alias u url_encode

      # Shortcut for Rack::Utils.unescape
      #
      # @param [#to_s] input
      # @return [String] URI-decoded representation of +input+
      def url_decode(input)
        Rack::Utils.unescape(input.to_s)
      end

      # Shortcut for Rack::Utils.escape_html
      #
      # @param [#to_s] input
      # @return [String]
      def html_escape(input)
        Rack::Utils.escape_html(input.to_s)
      end

      # Shortcut for CGI.unescapeHTML
      #
      # @param [#to_s] input
      # @return [String]
      def html_unescape(input)
        ::CGI.unescapeHTML(input.to_s)
      end

      # safely escape all HTML and code
      def html_and_code_escape(input)
        Rack::Utils.escape_html(input.to_s).gsub(/#([{@$]@?)/, '&#35;\1')
      end
      alias h html_and_code_escape

      # aliases are ignored by module_function...
      module_function :u, :h
    end
  end
end
