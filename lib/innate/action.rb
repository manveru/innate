module Innate
  class Action < Struct.new(:node, :method, :params, :view, :layout, :instance,
                            :exts, :wish, :options, :variables, :value,
                            :view_value)
  end unless defined?(Innate::Action)

  class Action
    def self.create(hash)
      new(*members.map{|m| hash[m.to_sym] })
    end

    CONTENT_TYPE = {
      'sass' => 'text/css',
    }

    WISH_TRANSFORM = {
      'json' => ['json', :to_json],
      'yaml' => ['yaml', :to_yaml],
    }

    def call
      wrap do
        setup
        render
      end
    end

    def wrap
      Current.actions << self
      yield
    ensure
      Current.actions.delete(self)
    end

    def content_type=(ct)
      @content_type = ct
    end

    private # think about internal API, don't expose it for now

    def setup
      self.instance = node.new
      self.value = instance.send(method, *params) if method
      self.view_value = File.read(view) if view
    end

    def render
      req, method = WISH_TRANSFORM[wish]

      if method
        require req if req
        node.response['Content-Type'] = content_type
        value.__send__(method)
      else
        wrap_in_layout{ fulfill_wish(view_value || value) }
      end
    end

    def fulfill_wish(string)
      way = File.basename(view).gsub!(/.*?#{wish}\./, '') if view

      if way ||= node.provide[wish]
        node.response['Content-Type'] = content_type
        View.get(way).render(self, string)
      else
        return nil
        # raise
      end
    end

    def content_type
      return @content_type if defined?(@content_type)
      fallback = CONTENT_TYPE[wish] || 'text/plain'
      @content_type = Rack::Mime.mime_type(".#{wish}", fallback)
    end

    def wrap_in_layout
      return yield unless layout

      layout_action = dup
      layout_action.view = layout
      layout_action.method = nil
      layout_action.layout = nil
      layout_action.variables[:content] = yield
      layout_action.call
    end
  end
end
