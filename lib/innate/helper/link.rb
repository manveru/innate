module Innate
  module Helper
    module Link
      def self.included(into)
        into.extend(self)
      end

      # Provide the path to given Node and actions.
      # Escapes GET parameters.
      #
      # Usage, mapping is Pages => '/', Users => '/users':
      #
      #   Pages.r                       # => URI('/')
      #   Pages.r(:foo)                 # => URI('/foo')
      #   Pages.r(:foo, :bar)           # => URI('/foo/bar')
      #   Pages.r(:foo, :a => :b)       # => URI('/foo?a=b')
      #   Pages.r(:foo, :bar, :a => :b) # => URI('/foo/bar?a=b')
      #
      #   Users.r                       # => URI('/users/')
      #   Users.r(:foo)                 # => URI('/users/foo')
      #   Users.r(:foo, :bar)           # => URI('/users/foo/bar')
      #   Users.r(:foo, :a => :b)       # => URI('/users/foo?a=b')
      #   Users.r(:foo, :bar, :a => :b) # => URI('/users/foo/bar?a=b')
      def route(name = '/', *args)
        hash = {}
        hashes, names = args.partition{|arg| arg.respond_to?(:merge!) }
        hashes.each{|to_merge| hash.merge!(to_merge) }

        location = Innate.to(self) || Innate.to(self.class)
        front = Array[location, name, *names].join('/').squeeze('/')

        if hash.empty?
          URI(front)
        else
          escape = Rack::Utils.method(:escape)
          query = hash.map{|key, value| "#{escape[key]}=#{escape[value]}" }.join(';')
          URI("#{front}?#{query}")
        end
      end
      alias r route

      # Usage, given Wiki is mapped to `/wiki`:
      #   Wiki.a(:home)                   # => '<a href="/wiki/home">home</a>'
      #   Wiki.a('home', :home)           # => '<a href="/wiki/home">home</a>'
      #   Wiki.a('home', :/)              # => '<a href="/wiki/">home</a>'
      #   Wiki.a('foo', :/, :foo => :bar) # => '<a href="/wiki/?foo=bar">foo</a>'
      def anchor(text, *args)
        href = args.empty? ? r(text) : r(*args)
        text = Rack::Utils.escape_html(text)
        %(<a href="#{href}">#{text}</a>)
      end
      alias a anchor
    end
  end
end
