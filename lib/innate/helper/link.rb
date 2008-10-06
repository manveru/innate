module Innate
  module Helper
    module Link
      DEFAULT << self

      def self.included(into)
        into.extend(self)
      end

      def r(name, *args)
        hash = {}
        hashes, names = args.partition{|arg| arg.respond_to?(:merge!) }
        hashes.each{|h| hash.merge!(h) }

        location = Innate.to(self) || Innate.to(self.class)
        front = Array[location, name, *names].join('/').squeeze('/')

        if hash.empty?
          URI(front)
        else
          u = Rack::Utils.method(:escape)
          query = hash.map{|k,v| "#{u[k]}=#{u[v]}" }.join(';')
          URI("#{front}?#{query}")
        end
      end

      # Usage, given Wiki is mapped to `/wiki`:
      #   Wiki.a(:home)                   # => '<a href="/wiki/home">home</a>'
      #   Wiki.a('home', :home)           # => '<a href="/wiki/home">home</a>'
      #   Wiki.a('home', :/)              # => '<a href="/wiki/">home</a>'
      #   Wiki.a('foo', :/, :foo => :bar) # => '<a href="/wiki/?foo=bar">foo</a>'

      def a(text, *args)
        href = args.empty? ? r(text) : r(*args)
        text = Rack::Utils.escape_html(text)
        %(<a href="#{href}">#{text}</a>)
      end
    end
  end
end
