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
      #
      # @return [URI] to the location
      def route(name = '/', *args)
        hash = {}
        hashes, names = args.partition{|arg| arg.respond_to?(:merge!) }
        hashes.each{|to_merge| hash.merge!(to_merge) }

        escape = Rack::Utils.method(:escape)
        location = route_location(self)
        front = Array[location, name, *names.map{|n| escape[n]}].join('/').squeeze('/')

        return URI(front) if hash.empty?

        query = hash.map{|k, v| "#{escape[k]}=#{escape[v]}" }.join(';')
        URI("#{front}?#{query}")
      end
      alias r route

      def route_location(klass)
        prefix = Innate.options.prefix
        location = Innate.to(klass) || Innate.to(klass.class)
        [prefix, location].join('/')
      end

      # Create a route to the currently active Node.
      #
      # This method is mostly here in case you include this helper elsewhere
      # and don't want (or can't) type SomeNode.r all the time.
      #
      # The usage is identical with {route}.
      #
      # @param [#to_s] name
      # @return [URI] to the location
      # @see Ramaze::Helper::Link#route
      # @author manveru
      def route_self(name = '/', *args)
        Current.action.node.route(name, *args)
      end
      alias rs route_self

      # Create a link tag
      #
      # Usage, given Wiki is mapped to `/wiki`:
      #
      #   Wiki.a(:home)                   # => '<a href="/wiki/home">home</a>'
      #   Wiki.a('home', :home)           # => '<a href="/wiki/home">home</a>'
      #   Wiki.a('home', :/)              # => '<a href="/wiki/">home</a>'
      #   Wiki.a('foo', :/, :foo => :bar) # => '<a href="/wiki/?foo=bar">foo</a>'
      #   Wiki.a('example', 'http://example.com')
      #   # => '<a href="http://example.com">example</a>'
      #
      # @return [String]
      def anchor(text, *args)
        case first = (args.first || text)
        when URI
          href = first.to_s
        when /^\w+:\/\//
          uri = URI(first)
          uri.query = Rack::Utils.escape_html(uri.query)
          href = uri.to_s
        else
          href = args.empty? ? r(text) : r(*args)
        end

        text = Rack::Utils.escape_html(text)
        %(<a href="#{href}">#{text}</a>)
      end
      alias a anchor
    end
  end
end
