module Innate
  module Helper
    module Render
      # Enables you to simply call:
      #
      # @example of added functionality
      #   YourController.render_partial(:foo, :x => 42)
      def self.included(into)
        into.extend(self)
      end

      # Renders the full action in the way a real request would.
      #
      # Please be aware that, if this is the first request from a client, you
      # will not have access to the session in the action being rendered, as no
      # actual session has been put into place yet.
      #
      # It should work as expected on any subsequent requests.
      #
      # As usual, patches welcome.
      #
      # @example usage
      #
      #   render_full('/blog/article/1')
      #   render_full('/blog/article/1', :lang => :de)
      #
      # Please note that you have to give the full path in the same way you'd
      # do in a direct request with curl or a browser.
      #
      # @api external
      # @see Mock.session
      # @author manveru
      def render_full(path, query = {})
        uri = URI(path.to_s)
        uri.query = Rack::Utils.build_query(query)

        if cookie = request.env['HTTP_COOKIE']
          Mock.session do |mock|
            mock.cookie = cookie
            return mock.get(uri.to_s).body
          end
        else
          Mock.get(uri.to_s).body
        end
      end

      # Renders an action without any layout.
      # You can further tweak the action to be rendered by passing a block.
      #
      # @example usage
      #
      #   render_partial(:index)
      #   render_partial(:index, :title => :foo)
      #
      # Please note that you only have to supply the action name, if your
      # action requires arguments then you have to pass a name suitable for
      # that.
      #
      # @example usage with action that requires arguments
      #
      #   # requires two arguments
      #   def foo(a, b)
      #   end
      #
      #   # pass two suitable arguments
      #   render_partial('foo/1/2')
      #
      # @api external
      # @see render_custom
      # @author manveru
      def render_partial(action_name, variables = {})
        render_custom(action_name, variables) do |action|
          action.layout = nil
          yield(action) if block_given?
        end
      end

      # Renders an action view, doesn't execute any methods and won't wrap it
      # into a layout.
      # You can further tweak the action to be rendered by passing a block.
      #
      # @example usage
      #
      #   render_view(:index)
      #   render_view(:index, :title => :foo)
      #
      # @api external
      # @see render_custom
      # @author manveru
      def render_view(action_name, variables = {})
        render_custom(action_name, variables) do |action|
          action.layout = nil
          action.method = nil
          yield(action) if block_given?
        end
      end

      # Use the given file as a template and render it in the same scope as
      # the current action.
      # The +filename+ may be an absolute path or relative to the process
      # working directory.
      #
      # @example usage
      #
      #   path = '/home/manveru/example/app/todo/view/index.xhtml'
      #   render_file(path)
      #   render_file(path, :title => :foo)
      #
      # Ramaze will emit a warning if you try to render an Action without a
      # method or view template, but will still try to render it.
      # The usual {Action#valid?} doesn't apply here, as sometimes you just
      # cannot have a method associated with a template.
      #
      # @api external
      # @see render_custom
      # @author manveru
      def render_file(filename, variables = {})
        action = Action.create(:view => filename)
        action.sync_variables(self.action)

        action.node      = self.class
        action.engine    = self.action.engine
        action.instance  = action.node.new
        action.variables = variables.dup

        yield(action) if block_given?

        valid_action = action.view || action.method
        Log.warn("Empty action: %p" % [action]) unless valid_action
        action.render
      end

      # @api internal
      # @author manveru
      def render_custom(action_name, variables = {})
        unless action = resolve(action_name.to_s)
          raise(ArgumentError, "No Action %p on #{self}" % [action_name])
        end

        action.sync_variables(self.action)
        action.instance = action.node.new
        action.variables = action.variables.merge(variables)

        yield(action) if block_given?

        valid_action = action.view || action.method
        Log.warn("Empty action: %p" % [action]) unless valid_action
        action.render
      end
    end
  end
end
