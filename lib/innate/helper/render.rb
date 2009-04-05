module Innate
  module Helper
    module Render
      # Renders the full action in the way a real request would.
      #
      # Please be aware that, if this is the first request from a client, you
      # will not have access to the session in the action being rendered, as no
      # actual session has been put into place yet.
      #
      # It should work as expected on any subsequent requests.
      #
      # As usual, patches welcome.
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
      def render_partial(name, variables = {})
        render_custom(name, variables) do |action|
          action.layout = nil
        end
      end

      # Renders an action view, doesn't execute any methods and won't wrap it
      # into a layout.
      def render_view(name, variables = {})
        render_custom(name, variables) do |action|
          action.layout = nil
          action.method = nil
        end
      end

      # Renders an action with the template of your choice.
      def render_template(name, file, variables = {})
        render_custom(name, variables) do |action|
          action.view = file
        end
      end

      def render_custom(name, variables = {})
        action = resolve(name.to_s)

        action.instance = action.node.new
        action.variables = action.variables.merge(variables)

        yield(action) if block_given?

        action.render if action.valid?
      end
    end
  end
end
