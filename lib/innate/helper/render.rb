module Innate
  module Helper
    module Render
      # Enables you to simply call:
      #
      # @example of added functionality
      #   YourController.render_partial(:foo, :x => 42)
      #
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
      # @api external
      # @see render_custom
      # @author manveru
      def render_partial(action_name, variables = {})
        render_custom(action_name, variables) do |action|
          action.layout = nil
        end
      end

      # Renders an action view, doesn't execute any methods and won't wrap it
      # into a layout.
      #
      # @api external
      # @see render_custom
      # @author manveru
      def render_view(action_name, variables = {})
        render_custom(action_name, variables) do |action|
          action.layout = nil
          action.method = nil
        end
      end

      def render_custom(action_name, variables = {})
        action = resolve(action_name.to_s)

        action.sync_variables(self.action)
        action.instance = action.node.new
        action.variables = action.variables.merge(variables)

        yield(action) if block_given?

        if action.valid?
          action.render
        else
          Log.warn("Invalid action: %p" % action)
        end
      end
    end
  end
end
