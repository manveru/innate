module Innate

  # The nervous system of {Innate}, so you can relax.
  #
  # Node may be included into any class to make it a valid responder to
  # requests.
  #
  # The major difference between this and the old Ramaze controller is that
  # every Node acts as a standalone application with its own dispatcher.
  #
  # What's also an important difference is the fact that {Node} is a module, so
  # we don't have to spend a lot of time designing the perfect subclassing
  # scheme.
  #
  # This makes dispatching more fun, avoids a lot of processing that is done by
  # {Rack} anyway and lets you tailor your application down to the last action
  # exactly the way you want without worrying about side-effects to other
  # {Node}s.
  #
  # Upon inclusion, it will also include {Innate::Trinity} and {Innate::Helper}
  # to provide you with {Innate::Request}, {Innate::Response},
  # {Innate::Session} instances, and all the standard helper methods as well as
  # the ability to simply add other helpers.
  #
  # NOTE:
  #   * Although I tried to minimize the amount of code in here there is still
  #     quite a number of methods left in order to do ramaze-style lookups.
  #     Those methods, and all other methods occurring in the ancestors after
  #     {Innate::Node} will not be considered valid action methods and will be
  #     ignored.
  #   * This also means that method_missing will not see any of the requests
  #     coming in.
  #   * If you want an action to act as a catch-all, use `def index(*args)`.

  module Node
    include Traited

    DEFAULT_HELPERS = %w[aspect cgi flash link partial redirect send_file]
    NODE_LIST = Set.new

    trait(:layout => nil, :alias_view => {}, :provide => {},
          :method_arities => {}, :wrap => [:aspect_wrap], :provide_set => false)

    # Upon inclusion we make ourselves comfortable.
    def self.included(into)
      into.__send__(:include, Helper)
      into.helper(*DEFAULT_HELPERS)

      into.extend(Trinity, self)

      NODE_LIST << into

      return if into.ancestral_trait[:provide_set]
      into.provide(:html => :erb, :yaml => :yaml, :json => :json)
      into.trait(:provide_set => false)
    end

    def self.setup
      NODE_LIST.each{|node| Innate.map(node.mapping, node) }
      Log.debug("Mapped Nodes: %p" % DynaMap::MAP)
    end

    # @return [String] the relative path to the node
    def mapping
      mapped = Innate.to(self)
      return mapped if mapped
      return '/' if NODE_LIST.size == 1
      "/" << self.name.gsub(/\B[A-Z][^A-Z]/, '_\&').downcase
    end

    # Shortcut to map or remap this Node
    # @param [#to_s] location
    def map(location)
      Innate.map(location, self)
    end

    # This little piece of nasty looking code enables you to provide different
    # content from a single action.
    #
    # @example
    #
    #   class Feeds
    #     include Innate::Node
    #     map '/feed'
    #
    #     provide :html => :erb, :rss => :erb, :atom => :erb
    #
    #     def index
    #       @feed = build_some_feed
    #     end
    #   end
    #
    # This will do following to these requests:
    #
    # /feed      # => call Feeds#index with template /view/feed/index.erb
    # /feed.atom # => call Feeds#index with template /view/feed/index.atom.erb
    # /feed.rss  # => call Feeds#index with template /view/feed/index.rss.erb
    #
    # If index.atom.erb isn't available we fall back to /view/feed/index.erb
    #
    # So it's really easy to add your own content representation.
    #
    # If no matching provider is found for the given extension it will fall
    # back to the one specified for html.
    #
    # The correct templating engine is selected by matching the last extension
    # of the template itself to the one set in Innate::View.
    #
    # If you don't want that your response is passed through a templating
    # engine, use :none like:
    #
    #   provide :txt => :none
    #
    # So a request to
    #
    # /feed.txt # => call Feeds#index with template /view/feed/index.txt.erb
    #
    # NOTE: provides also have effect on the chosen layout for the action.
    #
    # Given a Node at '/' with `layout('default')`:
    #   /layout/default.erb
    #   /layout/default.rss.erb
    #   /view/index.erb
    #   /view/feed.rss.erb
    #
    # /feed.rss will wrap /view/feed.rss.erb in /layout/default.rss.erb
    # /index    will wrap /view/index.erb    in /layout/default.erb

    def provide(formats = {})
      return ancestral_trait[:provide] if formats.empty?

      hash = {}
      formats.each{|pr, as| hash[pr.to_s] = Array[*as].map{|a| a.to_s } }
      trait(:provide => hash, :provide_set => true)

      ancestral_trait[:provide]
    end

    # This makes the Node a valid application for Rack.
    # +env+ is the environment hash passed from the Rack::Handler
    #
    # We rely on correct PATH_INFO.
    #
    # As defined by the Rack spec, PATH_INFO may be empty if it wants the root
    # of the application, so we insert '/' to make our dispatcher simple.
    #
    # Innate will not rescue any errors for you or do any error handling, this
    # should be done by an underlying middleware.
    #
    # We do however log errors at some vital points in order to provide you
    # with feedback in your logs.
    #
    # NOTE:
    #   * A lot of functionality in here relies on the fact that call is
    #     executed within Innate::STATE.wrap which populates the variables used
    #     by Trinity.
    #   * If you use the Node directly as a middleware make sure that you #use
    #     Innate::Current as a middleware before it.

    def call(env)
      path = env['PATH_INFO']
      path << '/' if path.empty?

      response.reset
      response = try_resolve(path)
      response['Content-Type'] ||= 'text/html'

      Current.session.flush(response)

      response.finish
    end

    # Let's try to find some valid action for given +path+.
    # Otherwise we dispatch to action_missing
    #
    # @param [String] path from request['REQUEST_PATH']
    def try_resolve(path)
      action = resolve(path)
      action ? action_found(action) : action_missing(path)
    end

    # Executed once an Action has been found.
    # Reset the {Innate::Response} instance, catch :respond and :redirect.
    # {Action#call} has to return a String.
    #
    # @param [Innate::Action] action
    # @return [Innate::Response]
    def action_found(action)
      result = catch(:respond){ catch(:redirect){ action.call }}

      if result.respond_to?(:finish)
        return result
      else
        Current.response.write(result)
        return Current.response
      end
    end

    # The default handler in case no action was found, kind of method_missing.
    # Must modify the response in order to have any lasting effect.
    #
    # Reasoning:
    # * We are doing this is in order to avoid tons of special error handling
    #   code that would impact runtime and make the overall API more
    #   complicated.
    # * This cannot be a normal action is that methods defined in
    #   {Innate::Node} will never be considered for actions.
    #
    # To use a normal action with template do following:
    #
    # @example
    #
    #   class Hi
    #     include Innate::Node
    #     map '/'
    #
    #     def self.action_missing(path)
    #       return if path == '/not_found'
    #       # No normal action, runs on bare metal
    #       try_resolve('/not_found')
    #     end
    #
    #     def not_found
    #       # Normal action
    #       "Sorry, I do not exist"
    #     end
    #   end
    #
    # @param [String] path
    # @see Innate::Response Node::try_resolve
    def action_missing(path)
      response.status = 404
      response['Content-Type'] = 'text/plain'
      response.write("No action found at: %p" % path)

      response
    end

    # Let's get down to business, first check if we got any wishes regarding
    # the representation from the client, otherwise we will assume he wants
    # html.
    #
    # @param [String] path
    # @return [nil Action]
    # @see Node::find_provide Node::update_method_arities Node::find_action
    # @author manveru
    def resolve(path)
      name, wish = find_provide(path)
      update_method_arities
      find_action(name, wish)
    end

    # @param [String] path
    # @return [Array] with name and wish
    # @see Node::provide
    # @author manveru
    def find_provide(path)
      name, wish = path, 'html'

      provide.find do |key, value|
        next unless path =~ /^(.+)\.#{key}$/i
        name, wish = $1, key
      end

      return name, wish
    end

    # Now we're talking Action, we try to find a matching template and method,
    # if we can't find either we go to the next pattern, otherwise we answer
    # with an Action with everything we know so far about the demands of the
    # client.
    #
    # @param [String] given_name the name extracted from REQUEST_PATH
    # @param [String] wish
    # @author manveru
    def find_action(given_name, wish)
      needs_method = Innate.options.action.needs_method

      patterns_for(given_name) do |name, params|
        method = find_method(name, params)
        view = find_view(name, wish)

        next unless view or method
        next unless method if needs_method
        next unless method if params.any?

        layout = find_layout(name, wish)
        params ||= []

        Action.create(:method => method, :params => params, :layout => layout,
                      :node => self, :view => view, :wish => wish)
      end
    end

    # @todo allow layouts combined of method and view... hairy :)
    def find_layout(name, wish)
      return unless layout = ancestral_trait[:layout]
      return unless layout = layout.call(name, wish) if layout.respond_to?(:call)

      if found = to_layout(layout, wish)
        [:layout, found]
      elsif found = find_view(layout, wish)
        [:view, found]
      elsif found = find_method(layout, [])
        [:method, found]
      end
    end

    # I hope this method talks for itself, we check arity if possible, but will
    # happily dispatch to any method that has default parameters.
    # If you don't want your method to be responsible for messing up a request
    # you should think twice about the arguments you specify due to limitations
    # in Ruby.
    #
    # So if you want your method to take only one parameter which may have a
    # default value following will work fine:
    #
    #   def index(foo = "bar", *rest)
    #
    # But following will respond to /arg1/arg2 and then fail due to ArgumentError:
    #
    #   def index(foo = "bar")
    #
    # Here a glance at how parameters are expressed in arity:
    #
    #   def index(a)                  # => 1
    #   def index(a = :a)             # => -1
    #   def index(a, *r)              # => -2
    #   def index(a = :a, *r)         # => -1
    #
    #   def index(a, b)               # => 2
    #   def index(a, b, *r)           # => -3
    #   def index(a, b = :b)          # => -2
    #   def index(a, b = :b, *r)      # => -2
    #
    #   def index(a = :a, b = :b)     # => -1
    #   def index(a = :a, b = :b, *r) # => -1
    #
    # @todo Once 1.9 is mainstream we can use Method#parameters to do accurate
    #       prediction
    def find_method(name, params)
      return unless arity = trait[:method_arities][name]
      name if arity == params.size or arity < 0
    end

    # Answer with a hash, keys are method names, values are method arities.
    #
    # Note that this will be executed once for every request, once we have
    # settled things down a bit more we can switch to update based on Reloader
    # hooks and update once on startup.
    # However, that may cause problems with dynamically created methods, so
    # let's play it safe for now.
    #
    # @example
    #
    #   Hi.update_method_arities
    #   # => {'index' => 0, 'foo' => -1, 'bar => 2}
    #
    # @see Node::resolve
    # @return [Hash] mapping the name of the methods to their arity
    def update_method_arities
      arities = {}
      trait(:method_arities => arities)

      exposed = ancestors & Helper::EXPOSE.to_a
      higher = ancestors.select{|a| a < Innate::Node }

      (higher + exposed).reverse_each do |ancestor|
        ancestor.public_instance_methods(false).each do |im|
          arities[im.to_s] = ancestor.instance_method(im).arity
        end
      end

      arities
    end

    # Try to find the best template for the given basename and wish.
    # Also, having extraordinarily much fun with globs.
    def find_view(file, wish)
      aliased = find_aliased_view(file, wish)
      return aliased if aliased

      path = [Innate.options.app.root, Innate.options.app.view, view_root, file]
      to_template(path, wish)
    end

    # This is done to make you feel more at home, pass an absolute path or a
    # path relative to your application root to set it, otherwise you'll get
    # the current mapping.
    def view_root(location = nil)
      return @view_root = location if location
      @view_root ||= Innate.to(self)
    end

    # Aliasing one view from another.
    # The aliases are inherited, and the optional third +node+ parameter
    # indicates the Node to take the view from.
    #
    # The argument order is identical with `alias` and `alias_method`, which
    # quite honestly confuses me, but at least we stay consistent.
    #
    # @example
    #   class Foo
    #     include Innate::Node
    #
    #     # Use the 'foo' view when calling 'bar'
    #     alias_view 'bar', 'foo'
    #
    #     # Use the 'foo' view from FooBar node when calling 'bar'
    #     alias_view 'bar', 'foo', FooBar
    #   end
    #
    # Note that the parameters have been simplified in comparision with
    # Ramaze::Controller::template where the second parameter may be a
    # Controller or the name of the template.  We take that now as an optional
    # third parameter.
    #
    # @param [#to_s]      to   view that should be replaced
    # @param [#to_s]      from view to use or Node.
    # @param [#nil? Node] node optionally obtain view from this Node
    # @see Node::find_aliased_view
    # @author manveru
    def alias_view(to, from, node = nil)
      trait[:alias_view] || trait(:alias_view => {})
      trait[:alias_view][to.to_s] = node ? [from.to_s, node] : from.to_s
    end

    # @param [String] file
    # @param [String] wish
    # @return [nil String] the absolute path to the aliased template or nil
    # @see Node::alias_view Node::find_view
    # @author manveru
    def find_aliased_view(file, wish)
      aliased_file, aliased_node = ancestral_trait[:alias_view][file]
      aliased_node ||= self
      aliased_node.find_view(aliased_file, wish) if aliased_file
    end

    # Find the best matching file for the layout, if any.
    #
    # @param [String] file
    # @param [String] wish
    # @return [nil String] the absolute path to the template or nil
    # @see Node::to_template
    # @author manveru
    def to_layout(file, wish)
      path = [Innate.options.app.root, Innate.options.app.layout, file]
      to_template(path, wish)
    end

    # @param [String] file
    # @param [String] wish
    # @return [nil String] the absolute path to the template or nil
    # @see Node::find_view Node::to_layout Node::find_aliased_view
    # @author manveru
    def to_template(path, wish)
      return unless path.all?

      path = File.join(*path.map{|pa| pa.to_s.split('__') }.flatten)
      exts = (Array[provide[wish]] + provide.keys).flatten.compact.uniq.join(',')
      glob = "#{path}.{#{wish}.,#{wish},}{#{exts},}"
      found = Dir[glob].uniq

      if found.size > 1
        Log.warn("%d views found for %p | %p" % [found.size, path, wish])
      end

      found.first
    end

    # Define a layout to use on this Node.
    #
    # @param [String #to_s] name basename without extension of the layout to use
    # @param [Proc #call] block called on every dispatch if no name given
    # @return [Proc String] The assigned name or block
    #
    # @note The behaviour of Node#layout changed significantly from Ramaze,
    #   instead of multitudes of obscure options and methods like deny_layout
    #   we simply take a block and use the returned value as the name for the
    #   layout. No layout will be used if the block returns nil.
    def layout(name = nil, &block)
      if name and block
        trait(:layout => lambda{|n, w| name if block.call(n, w) })
      elsif name
        trait(:layout => name.to_s)
      elsif block
        trait(:layout => block)
      end

      return ancestral_trait[:layout]
    end

    # The innate beauty in Nitro, Ramaze, and {Innate}.
    #
    # Will yield the name of the action and parameter for the action method in
    # order of significance.
    #
    #   def foo__bar # responds to /foo/bar
    #   def foo(bar) # also responds to /foo/bar
    #
    # But foo__bar takes precedence because it's more explicit.
    #
    # The last fallback will always be the index action with all of the path
    # turned into parameters.
    #
    # @usage
    #   class Foo; include Innate::Node; map '/'; end
    #
    #   Foo.patterns_for('/'){|action, params| p action => params }
    #   # => {"index"=>[]}
    #
    #   Foo.patterns_for('/foo/bar'){|action, params| p action => params }
    #   # => {"foo__bar"=>[]}
    #   # => {"foo"=>["bar"]}
    #   # => {"index"=>["foo", "bar"]}
    #
    #   Foo.patterns_for('/foo/bar/baz'){|action, params| p action => params }
    #   # => {"foo__bar__baz"=>[]}
    #   # => {"foo__bar"=>["baz"]}
    #   # => {"foo"=>["bar", "baz"]}
    #   # => {"index"=>["foo", "bar", "baz"]}
    def patterns_for(path)
      atoms = path.split('/')
      atoms.delete('')
      result = nil

      atoms.size.downto(0) do |len|
        action = atoms[0...len].join('__')
        params = atoms[len..-1]
        action = 'index' if action.empty?

        return result if result = yield(action, params)
      end

      return nil
    end

    # This awesome piece of hackery implements action AOP, methods may register
    # themself in the trait[:wrap] and will be called in left-to-right order,
    # each being passed the action instance and a block that they have to yield
    # to continue the chain.
    #
    # This enables things like action logging, caching, aspects,
    # authentication, etc...
    #
    # @param [Action] action instance that is being passed to every registered method
    # @param [Proc] block contains the instructions to call the action method if any
    # @see Action#render
    # @author manveru
    def wrap_action_call(action, &block)
      wrap = ancestral_trait[:wrap]

      head, tail = wrap[0], wrap[1..-1].reverse
      combined = tail.inject(block){|s,v| lambda{ __send__(v, action, &s) } }
      __send__(head, action, &combined)
    end

    # For compatibility with new Kernel#binding behaviour in 1.9
    #
    # @return [Binding] binding of the instance being rendered.
    # @see Action#binding
    # @author manveru
    def binding; super; end
  end

  module SingletonMethods
    # Convenience method to include the Node module into +node+ and map to a
    # +location+.
    #
    # @param [#to_s]    location where the node is mapped to
    # @param [Node nil] node     the class that will be a node, will try to look it
    #                            up if not given
    # @return [Class] the node argument or detected class will be returned
    # @see Innate::node_from_backtrace
    # @author manveru
    def node(location, node = nil)
      node ||= node_from_backtrace(caller)
      node.__send__(:include, Node)
      node.map(location)
      node
    end

    # Cheap hack that works reasonably well to avoid passing self all the time
    # to Innate::node
    # We simply search the file that Innate::node was called in for the first
    # class definition above the line that Innate::node was called and look up
    # the constant.
    # If there are any problems with this (filenames containing ':' or
    # metaprogramming) just pass the node parameter explicitly to Innate::node
    #
    # @param [Array #[]] backtrace
    # @see Innate::node
    # @author manveru
    def node_from_backtrace(backtrace)
      file, line = backtrace[0].split(':', 2)
      line = line.to_i
      File.readlines(file)[0..line].reverse.find{|line| line =~ /^\s*class\s+(\S+)/ }
      const_get($1)
    end
  end
end
