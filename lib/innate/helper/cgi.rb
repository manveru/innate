autoload(:CGI, 'cgi') # in case you want to use html_unescape

module Innate

  # Shortcuts to some CGI methods

  module Helper
    module CGI
      # shortcut for Rack::Utils.escape
      def url_encode(*args)
        Rack::Utils.escape(*args.map{|a| a.to_s })
      end

      # shortcut for Rack::Utils.unescape
      def url_decode(*args)
        Rack::Utils.unescape(*args.map{|a| a.to_s })
      end

      # shortcut for Rack::Utils.escape_html
      def html_escape(string)
        Rack::Utils.escape_html(string)
      end

      # shortcut for CGI.unescapeHTML
      def html_unescape(string)
        ::CGI.unescapeHTML(string.to_s)
      end

      # safely escape all HTML and code
      def h(string)
        Rack::Utils.escape_html(string).gsub(/#([{@$]@?)/, '&#35;\1')
      end

      # one-letter versions help in case like #{h foo.inspect}
      # ERb/ERuby/Rails compatible
      alias u url_encode

      module_function(:url_encode, :url_decode, :html_escape, :html_unescape, :h, :u)
    end
  end
end
