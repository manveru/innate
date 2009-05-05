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
  # Please note that method_missing will _not_ be considered when building an
  # {Action}. There might be future demand for this, but for now you can simply
  # use `def index(*args); end` to make a catch-all action.
  module Node
    include Traited

    attr_reader :method_arities, :layout_templates, :view_templates

    NODE_LIST = Set.new

    # These traits are inherited into ancestors, changing a trait in an
    # ancestor doesn't affect the higher ones.
    #
    #   class Foo; include Innate::Node; end
    #   class Bar < Foo; end
    #
    #   Foo.trait[:wrap] == Bar.trait[:wrap] # => true
    #   Bar.trait(:wrap => [:cache_wrap])
    #   Foo.trait[:wrap] == Bar.trait[:wrap] # => false

    trait :views          => []
    trait :layouts        => []
    trait :layout         => nil
    trait :alias_view     => {}
    trait :provide        => {}

    # @see wrap_action_call
    trait :wrap           => SortedSet.new
    trait :provide_set    => false
    trait :needs_method   => false
    trait :skip_node_map  => false

    # Upon inclusion we make ourselves comfortable.
    def self.included(into)
      into.__send__(:include, Helper)
      into.extend(Trinity, self)

      NODE_LIST << into

      return if into.provide_set?
      into.provide(:html, :engine => :Etanni)
      into.trait(:provide_set => false)
    end

    # node mapping procedure
    #
    # when Node is included into an object, it's added to NODE_LIST
    # when object::map(location) is sent, it maps the object into DynaMap
    # when Innate.start is issued, it calls Node::setup
    # Node::setup iterates NODE_LIST and maps all objects not in DynaMap by
    # using Node::generate_mapping(object.name) as location
    #
    # when object::map(nil) is sent, the object will be skipped in Node::setup

    def self.setup
      NODE_LIST.each{|node|
        node.map(generate_mapping(node.name)) unless node.trait[:skip_node_map]
      }
      # Log.debug("Mapped Nodes: %p" % DynaMap.to_hash) unless NODE_LIST.empty?
    end

    def self.generate_mapping(object_name = self.name)
      return '/' if NODE_LIST.size == 1
      parts = object_name.split('::').map{|part|
        part.gsub(/^[A-Z]+/){|sub| sub.downcase }.gsub(/[A-Z]+[^A-Z]/, '_\&')
      }
      '/' << parts.join('/').downcase
    end

    # Tries to find the relative url that this {Node} is mapped to.
    # If it cannot find one it will instead generate one based on the
    # snake_cased name of itself.
    #
    # @example Usage:
    #
    #   class FooBar
    #     include Innate::Node
    #   end
    #   FooBar.mapping # => '/foo_bar'
    #
    # @return [String] the relative path to the node
    #
    # @api external
    # @see Innate::SingletonMethods#to
    # @author manveru
    def mapping
      Innate.to(self)
    end

    # Shortcut to map or remap this Node.
    #
    # @example Usage for explicit mapping:
    #
    #   class FooBar
    #     include Innate::Node
    #     map '/foo_bar'
    #   end
    #
    #   Innate.to(FooBar) # => '/foo_bar'
    #
    # @example Usage for automatic mapping:
    #
    #   class FooBar
    #     include Innate::Node
    #     map mapping
    #   end
    #
    #   Innate.to(FooBar) # => '/foo_bar'
    #
    # @param [#to_s] location
    #
    # @api external
    # @see Innate::SingletonMethods::map
    # @author manveru
    def map(location)
      trait :skip_node_map => true
      Innate.map(location, self) if location
    end

    # Specify which way contents are provided and processed.
    #
    # Use this to set a templating engine, custom Content-Type, or pass a block
    # to take over the processing of the {Action} and template yourself.
    #
    # Provides set via this method will be inherited into subclasses.
    #
    # The +format+ is extracted from the PATH_INFO, it simply represents the
    # last extension name in the path.
    #
    # The provide also has influence on the chosen templates for the {Action}.
    #
    # @example providing RSS with ERB templating
    #
    #   provide :rss, :engine => :ERB
    #
    # Given a request to `/list.rss` the template lookup first tries to find
    # `list.rss.erb`, if that fails it falls back to `list.erb`.
    # If neither of these are available it will try to use the return value of
    # the method in the {Action} as template.
    #
    # A request to `/list.yaml` would match the format 'yaml'
    #
    # @example providing a yaml version of actions
    #
    #   class Articles
    #     include Innate::Node
    #     map '/article'
    #
    #     provide(:yaml, :type => 'text/yaml'){|action, value| value.to_yaml }
    #
    #     def list
    #       @articles = Article.list
    #     end
    #   end
    #
    # @example providing plain text inspect version
    #
    #   class Articles
    #     include Innate::Node
    #     map '/article'
    #
    #     provide(:txt, :type => 'text/plain'){|action, value| value.inspect }
    #
    #     def list
    #       @articles = Article.list
    #     end
    #   end
    #
    # @param [Proc] block
    #   upon calling the action, [action, value] will be passed to it and its
    #   return value becomes the response body.
    #
    # @option param :engine [Symbol String]
    #   Name of an engine for View::get
    # @option param :type [String]
    #   default Content-Type if none was set in Response
    #
    # @raise [ArgumentError] if neither a block nor an engine was given
    #
    # @api external
    # @see View::get Node#provides
    # @author manveru
    #
    # @todo
    #   The comment of this method may be too short for the effects it has on
    #   the rest of Innate, if you feel something is missing please let me
    #   know.

    def provide(format, param = {}, &block)
      if param.respond_to?(:to_hash)
        param = param.to_hash
        handler = block || View.get(param[:engine])
        content_type = param[:type]
      else
        handler = View.get(param)
      end

      raise(ArgumentError, "Need an engine or block") unless handler

      trait("#{format}_handler"      => handler, :provide_set => true)
      trait("#{format}_content_type" => content_type) if content_type
    end

    def provides
      ancestral_trait.reject{|k,v| k !~ /_handler$/ }
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
    # A lot of functionality in here relies on the fact that call is executed
    # within Current#call which populates the variables used by Trinity.
    # So if you use the Node directly as a middleware make sure that you #use
    # Innate::Current as a middleware before it.
    #
    # @param [Hash] env
    #
    # @return [Array]
    #
    # @api external
    # @see Response#reset Node#try_resolve Session#flush
    # @author manveru

    def call(env)
      path = env['PATH_INFO']
      path << '/' if path.empty?

      response.reset
      try_resolve(path).finish
    end

    # Let's try to find some valid action for given +path+.
    # Otherwise we dispatch to {action_missing}.
    #
    # @param [String] path from env['PATH_INFO']
    #
    # @return [Response]
    #
    # @api external
    # @see Node#resolve Node#action_found Node#action_missing
    # @author manveru
    def try_resolve(path)
      action = resolve(path)
      action ? action_found(action) : action_missing(path)
    end

    # Executed once an {Action} has been found.
    #
    # Reset the {Innate::Response} instance, catch :respond and :redirect.
    # {Action#call} has to return a String.
    #
    # @param [Action] action
    #
    # @return [Innate::Response]
    #
    # @api external
    # @see Action#call Innate::Response
    # @author manveru
    def action_found(action)
      response = catch(:respond){ catch(:redirect){ action.call }}

      unless response.respond_to?(:finish)
        self.response.write(response)
        response = self.response
      end

      response['Content-Type'] ||= action.options[:content_type]
      response
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
    #
    # @api external
    # @see Innate::Response Node#try_resolve
    # @author manveru
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
    #
    # @return [nil, Action]
    #
    # @api external
    # @see Node::find_provide Node::update_method_arities Node::find_action
    # @author manveru
    def resolve(path)
      name, wish, engine = find_provide(path)
      node = (respond_to?(:ancestors) && respond_to?(:new)) ? self : self.class
      action = Action.create(:node => node, :wish => wish, :engine => engine, :path => path)

      if content_type = node.ancestral_trait["#{wish}_content_type"]
        action.options = {:content_type => content_type}
      end

      node.update_method_arities
      node.update_template_mappings
      node.fill_action(action, name)
    end

    # Resolve possible provides for the given +path+ from {provides}.
    #
    # @param [String] path
    #
    # @return [Array] with name, wish, engine
    #
    # @api internal
    # @see Node::provide Node::provides
    # @author manveru
    def find_provide(path)
      pr = provides

      name, wish, engine = path, 'html', pr['html_handler']

      pr.find do |key, value|
        key = key[/(.*)_handler$/, 1]
        next unless path =~ /^(.+)\.#{key}$/i
        name, wish, engine = $1, key, value
      end

      return name, wish, engine
    end

    # Now we're talking {Action}, we try to find a matching template and
    # method, if we can't find either we go to the next pattern, otherwise we
    # answer with an {Action} with everything we know so far about the demands
    # of the client.
    #
    # @param [String] given_name the name extracted from REQUEST_PATH
    # @param [String] wish
    #
    # @return [Action, nil]
    #
    # @api internal
    # @see Node#find_method Node#find_view Node#find_layout Node#patterns_for
    #      Action#wish Action#merge!
    # @author manveru
    def fill_action(action, given_name)
      needs_method = self.needs_method?
      wish = action.wish

      patterns_for(given_name) do |name, params|
        method = find_method(name, params)

        next unless method if needs_method
        next unless method if params.any?
        next unless (view = find_view(name, wish)) or method

        params.map!{|param| Rack::Utils.unescape(param) }

        action.merge!(:method => method, :view => view, :params => params,
                      :layout => find_layout(name, wish))
      end
    end

    # Try to find a suitable value for the layout. This may be a template or
    # the name of a method.
    #
    # If a layout could be found, an Array with two elements is returned, the
    # first indicating the kind of layout (:layout|:view|:method), the second
    # the found value, which may be a String or Symbol.
    #
    # @param [String] name
    # @param [String] wish
    #
    # @return [Array, nil]
    #
    # @api external
    # @see Node#to_layout Node#find_method Node#find_view
    # @author manveru
    #
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

    # We check arity if possible, but will happily dispatch to any method that
    # has default parameters.
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
    # @param [String, Symbol] name
    # @param [Array]         params
    #
    # @return [String, Symbol]
    #
    # @api external
    # @see Node#fill_action Node#find_layout
    # @author manveru
    #
    # @todo Once 1.9 is mainstream we can use Method#parameters to do accurate
    #       prediction
    def find_method(name, params)
      return unless arity = method_arities[name]
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
    # @api internal
    # @see Node#resolve
    # @return [Hash] mapping the name of the methods to their arity
    def update_method_arities
      @method_arities = {}

      exposed = ancestors & Helper::EXPOSE.to_a
      higher = ancestors.select{|a| a < Innate::Node }

      (higher + exposed).reverse_each do |ancestor|
        ancestor.public_instance_methods(false).each do |im|
          @method_arities[im.to_s] = ancestor.instance_method(im).arity
        end
      end

      @method_arities
    end

    # Try to find the best template for the given basename and wish and respect
    # aliased views.
    #
    # @param [#to_s] action_name
    # @param [#to_s] wish
    #
    # @return [String, nil] depending whether a template could be found
    #
    # @api external
    # @see Node#to_template Node#find_aliased_view
    # @author manveru
    def find_view(action_name, wish)
      aliased = find_aliased_view(action_name, wish)
      return aliased if aliased

      to_view(action_name, wish)
    end

    # Try to find the best template for the given basename and wish.
    #
    # This method is mostly here for symetry with {to_layout} and to allow you
    # overriding the template lookup easily.
    #
    # @param [#to_s] action_name
    # @param [#to_s] wish
    #
    # @return [String, nil] depending whether a template could be found
    #
    # @api external
    # @see {Node#find_view} {Node#to_template} {Node#root_mappings}
    #      {Node#view_mappings} {Node#to_template}
    # @author manveru
    def to_view(action_name, wish)
      return unless files = view_templates[wish.to_s]
      files[action_name.to_s]
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
    # @param [#nil?, Node] node optionally obtain view from this Node
    #
    # @api external
    # @see Node::find_aliased_view
    # @author manveru
    def alias_view(to, from, node = nil)
      trait[:alias_view] || trait(:alias_view => {})
      trait[:alias_view][to.to_s] = node ? [from.to_s, node] : from.to_s
    end

    # Resolve one level of aliasing for the given +action_name+ and +wish+.
    #
    # @param [String] action_name
    # @param [String] wish
    #
    # @return [nil, String] the absolute path to the aliased template or nil
    #
    # @api internal
    # @see Node::alias_view Node::find_view
    # @author manveru
    def find_aliased_view(action_name, wish)
      aliased_name, aliased_node = ancestral_trait[:alias_view][action_name]
      return unless aliased_name

      aliased_node ||= self
      aliased_node.update_view_mappings
      aliased_node.find_view(aliased_name, wish)
    end

    # Find the best matching action_name for the layout, if any.
    #
    # This is mostly an abstract method that you might find handy if you want
    # to do vastly different layout lookup.
    #
    # @param [String] action_name
    # @param [String] wish
    #
    # @return [nil, String] the absolute path to the template or nil
    #
    # @api external
    # @see {Node#to_template} {Node#root_mappings} {Node#layout_mappings}
    # @author manveru
    def to_layout(action_name, wish)
      return unless files = layout_templates[wish.to_s]
      files[action_name.to_s]
    end

    # Define a layout to use on this Node.
    #
    # A Node can only have one layout, although the template being chosen can
    # depend on {provides}.
    #
    # @param [String, #to_s] name basename without extension of the layout to use
    # @param [Proc, #call] block called on every dispatch if no name given
    #
    # @return [Proc, String] The assigned name or block
    #
    # @api external
    # @see Node#find_layout Node#layout_paths Node#to_layout Node#app_layout
    # @author manveru
    #
    # NOTE:
    #   The behaviour of Node#layout changed significantly from Ramaze, instead
    #   of multitudes of obscure options and methods like deny_layout we simply
    #   take a block and use the returned value as the name for the layout. No
    #   layout will be used if the block returns nil.
    def layout(name = nil, &block)
      if name and block
        # default name, but still check with block
        trait(:layout => lambda{|n, w| name if block.call(n, w) })
      elsif name
        # name of a method or template
        trait(:layout => name.to_s)
      elsif block
        # call block every request with name and wish, returned value is name
        # of layout template or method
        trait(:layout => block)
      else
        # remove layout for this node
        trait(:layout => nil)
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
    # @example yielding possible combinations of action names and params
    #
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
    #
    # @param [String, #split] path usually the PATH_INFO
    #
    # @return [Action] it actually returns the first non-nil/false result of yield
    #
    # @api internal
    # @see Node#fill_action
    # @author manveru
    def patterns_for(path)
      atoms = path.split('/')
      atoms.delete('')
      result = nil

      atoms.size.downto(0) do |len|
        action_name = atoms[0...len].join('__')
        params = atoms[len..-1]
        action_name = 'index' if action_name.empty? and params != ['index']

        return result if result = yield(action_name, params)
      end

      return nil
    end

    # Try to find a template at the given +path+ for +wish+.
    #
    # Since Innate supports multiple paths to templates the +path+ has to be an
    # Array that may be nested one level.
    #
    # @example Usage to find available templates
    #
    #   # This assumes following files:
    #   # view/foo.erb
    #   # view/bar.erb
    #   # view/bar.rss.erb
    #   # view/bar.yaml.erb
    #
    #   class FooBar
    #     Innate.node('/')
    #   end
    #
    #   FooBar.to_template(['.', 'view', '/', 'foo'], 'html')
    #   # => "./view/foo.erb"
    #   FooBar.to_template(['.', 'view', '/', 'foo'], 'yaml')
    #   # => "./view/foo.erb"
    #   FooBar.to_template(['.', 'view', '/', 'foo'], 'rss')
    #   # => "./view/foo.erb"
    #
    #   FooBar.to_template(['.', 'view', '/', 'bar'], 'html')
    #   # => "./view/bar.erb"
    #   FooBar.to_template(['.', 'view', '/', 'bar'], 'yaml')
    #   # => "./view/bar.yaml.erb"
    #   FooBar.to_template(['.', 'view', '/', 'bar'], 'rss')
    #   # => "./view/bar.rss.erb"
    #
    # @param [Array<Array<String>>, Array<String>] path
    #   array containing strings and nested (1 level) arrays containing strings
    # @param [String] wish
    #
    # @return [nil, String] relative path to the first template found
    #
    # @api external
    # @see Node#find_view Node#to_layout Node#find_aliased_view
    # @author manveru
    def to_template(path, wish)
      to_view(path, wish) || to_layout(path, wish)
    end

    def update_template_mappings
      update_view_mappings
      update_layout_mappings
    end

    def update_view_mappings
      paths = possible_paths_for(view_mappings)
      @view_templates = update_mapping_shared(paths)
    end

    def update_layout_mappings
      paths = possible_paths_for(layout_mappings)
      @layout_templates = update_mapping_shared(paths)
    end

    def update_mapping_shared(paths)
      mapping = {}
      paths.reject!{|path| !File.directory?(path) }

      provides.each do |wish_key, engine|
        wish = wish_key[/(.*)_handler/, 1]
        exts = possible_exts_for(wish)

        paths.reverse_each do |path|
          Find.find(path) do |file|
            exts.each do |ext|
              next unless file =~ ext

              case file.sub(path, '').gsub('/', '__')
              when /^(.*)\.(.*)\.(.*)$/
                action_name, wish_ext, engine_ext = $1, $2, $3
              when /^(.*)\.(.*)$/
                action_name, wish_ext, engine_ext = $1, wish, $2
              end

              mapping[wish_ext] ||= {}
              mapping[wish_ext][action_name] = file
            end
          end
        end
      end

      return mapping
    end

    # Answer with an array of possible paths in order of significance for
    # template lookup of the given +mappings+.
    #
    # @param [#map] An array two Arrays of inner and outer directories.
    #
    # @return [Array]
    # @see update_view_mappings update_layout_mappings update_template_mappings
    # @author manveru
    def possible_paths_for(mappings)
      root_mappings.map{|root|
        mappings.first.map{|inner|
          mappings.last.map{|outer|
            ::File.join(root, inner, outer, '/') }}}.flatten
    end

    # Answer with an array of possible extensions in order of significance for
    # the given +wish+.
    #
    # @param [#to_s] wish the extension (no leading '.')
    #
    # @return [Array] list of exts valid for this +wish+
    #
    # @api internal
    # @see Node#to_template View::exts_of Node#provides
    # @author manveru
    def possible_exts_for(wish)
      pr = provides
      return unless engine = pr["#{wish}_handler"]
      View.exts_of(engine).map{|e_ext|
        [[*wish].map{|w_ext| /#{w_ext}\.#{e_ext}$/ }, /#{e_ext}$/]
      }.flatten
    end

    # For compatibility with new Kernel#binding behaviour in 1.9
    #
    # @return [Binding] binding of the instance being rendered.
    # @see Action#binding
    # @author manveru
    def binding; super end

    # make sure this is an Array and a new instance so modification on the
    # wrapping array doesn't affect the original option.
    # [*arr].object_id == arr.object_id if arr is an Array
    #
    # @return [Array] list of root directories
    #
    # @api external
    # @author manveru
    def root_mappings
      [*options.roots].flatten
    end

    # Set the paths for lookup below the Innate.options.views paths.
    #
    # @param [String, Array<String>] locations
    #   Any number of strings indicating the paths where view templates may be
    #   located, relative to Innate.options.roots/Innate.options.views
    #
    # @return [Node] self
    #
    # @api external
    # @see {Node#view_mappings}
    # @author manveru
    def map_views(*locations)
      trait :views => locations.flatten.uniq
      self
    end

    # Combine Innate.options.views with either the `ancestral_trait[:views]`
    # or the {Node#mapping} if the trait yields an empty Array.
    #
    # @return [Array<String>, Array<Array<String>>]
    #
    # @api external
    # @see {Node#map_views}
    # @author manveru
    def view_mappings
      paths = [*ancestral_trait[:views]]
      paths = [mapping] if paths.empty?

      [[*options.views].flatten, [*paths].flatten]
    end

    # Set the paths for lookup below the Innate.options.layouts paths.
    #
    # @param [String, Array<String>] locations
    #   Any number of strings indicating the paths where layout templates may
    #   be located, relative to Innate.options.roots/Innate.options.layouts
    #
    # @return [Node] self
    #
    # @api external
    # @see {Node#layout_mappings}
    # @author manveru
    def map_layouts(*locations)
      trait :layouts => locations.flatten.uniq
      self
    end

    # Combine Innate.options.layouts with either the `ancestral_trait[:layouts]`
    # or the {Node#mapping} if the trait yields an empty Array.
    #
    # @return [Array<String>, Array<Array<String>>]
    #
    # @api external
    # @see {Node#map_layouts}
    # @author manveru
    def layout_mappings
      paths = [*ancestral_trait[:layouts]]
      paths = ['/'] if paths.empty?

      [[*options.layouts].flatten, [*paths].flatten]
    end

    def options
      Innate.options
    end

    # Whether an {Action} can be built without a method.
    #
    # The default is to allow actions that use only a view template, but you
    # might want to turn this on, for example if you have partials in your view
    # directories.
    #
    # @example turning needs_method? on
    #
    #   class Foo
    #     Innate.node('/')
    #   end
    #
    #   Foo.needs_method? # => true
    #   Foo.trait :needs_method => false
    #   Foo.needs_method? # => false
    #
    # @return [true, false] (false)
    #
    # @api external
    # @see {Node#fill_action}
    # @author manveru
    def needs_method?
      ancestral_trait[:needs_method]
    end

    # This will return true if the only provides set are by {Node::included}.
    #
    # The reasoning behind this is to determine whether the user has touched
    # the provides at all, in which case we will not override the provides in
    # subclasses.
    #
    # @return [true, false] (false)
    #
    # @api internal
    # @see {Node::included}
    # @author manveru
    def provide_set?
      ancestral_trait[:provide_set]
    end
  end

  module SingletonMethods
    # Convenience method to include the Node module into +node+ and map to a
    # +location+.
    #
    # @param [#to_s]    location where the node is mapped to
    # @param [Node, nil] node     the class that will be a node, will try to
    #                            look it up if not given
    #
    # @return [Class, Module]    the node argument or detected class will be
    #                            returned
    #
    # @api external
    # @see SingletonMethods::node_from_backtrace
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
    # @param [Array<String>, #[]] backtrace
    #
    # @return [Class, Module]
    #
    # @api internal
    # @see SingletonMethods::node
    # @author manveru
    def node_from_backtrace(backtrace)
      filename, lineno = backtrace[0].split(':', 2)
      regexp = /^\s*class\s+(\S+)/
      File.readlines(filename)[0..lineno.to_i].reverse.find{|l| l =~ regexp }
      const_get($1)
    end
  end
end
