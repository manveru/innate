module Org
  class RootToken < Token
    # little optimization, avoid check for root
    def to_html
      @childs.map{|child| child.to_html }.join
    end
  end

  module ToHtml
    def to_html
      method = "html_#{@name}"

      if respond_to?(method)
        send(method)
      elsif @childs.empty?
        Tag.new(name, values)
      else
        Tag.new(name, values){ @childs.map{|c| c.to_html }.join }
      end
    end

    def html_text
      Rack::Utils.escape_html(values.join)
    end

    # unify toc_id somwhere?
    def html_header
      level, text = values[0].size, values[1]
      id = respond_to?(:toc_id) ? toc_id : text.gsub(/\W/, '-').squeeze('-').downcase
      Tag.new("h#{level}", text, :id => id)
    end

    def html_space
      ' '
    end

    # TODO: find a simple way of caching highlighted code from Uv,
    #       gives us much more possibilities in highlighting compared
    #       to coderay, but is also _really_ slow.
    def html_highlight
      language, code = *values
      require 'coderay'
      language = 'nitro_xhtml' if language == 'ezamar'

      case language
      when *%w[ruby c delphi html nitro_xhtml plaintext rhtml xml]
        tokens = CodeRay.scan(code, language)
        html = tokens.html(:wrap => :div)
      when *%w[diff]
        require 'uv'
        Uv.parse(code, output = 'xhtml', syntax_name = language, line_numbers = false, render_style = 'amy', headers = false)
      else
        code = language if not code or code.strip.empty?
        html = tag(:pre, code)
      end
    end

    def tag(*args)
      Tag.new(*args)
    end
  end

  # Extracted from Ramaze Gestalt
  class Tag
    def initialize(name, value, args = {}, &block)
      @name, @value, @args, @block = name, value, args, block
    end

    def to_s
      @out = ''
      build_tag(@name, @args, @value, &@block)
      @out
    end

    def build_tag(name, attr = {}, text = [])
      @out << "<#{name}"
      @out << attr.map{|k,v| %[ #{k}="#{escape_entities(v)}"] }.join
      if text != [] or block_given?
        @out << ">"
        @out << escape_entities([text].join)
        if block_given?
          text = yield
          @out << text.to_str if text != @out and text.respond_to?(:to_str)
        end
        @out << "</#{name}>"
      else
        @out << ' />'
      end
    end

    def escape_entities(s)
      s.to_s.gsub(/&/, '&amp;').
        gsub(/"/, '&quot;').
        gsub(/'/, '&apos;').
        gsub(/</, '&lt;').
        gsub(/>/, '&gt;')
    end
  end
end
