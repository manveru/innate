module Innate
  ACTION_MEMBERS = [ :node, :method, :params, :view, :layout, :instance, :exts,
                     :wish, :options, :variables, :value, :view_value ]

  class Action < Struct.new(*ACTION_MEMBERS)
    def self.create(hash)
      new(*hash.values_at(*ACTION_MEMBERS))
    end

    def call
      Current.actions << self
      self.instance = node.new
      self.variables[:content] ||= nil
      render
    ensure
      Current.actions.delete(self)
    end

    def binding
      instance.binding
    end

    def sync_variables(from_action)
      instance = from_action.instance

      instance.instance_variables.each{|iv|
        iv_value = instance.instance_variable_get(iv)
        iv_name = iv.to_s[1..-1]
        self.variables[iv_name.to_sym] = iv_value
      }
    end

    # Copy variables to given binding.
    def copy_variables(binding = self.binding)
      if variables.any?
        binding.eval('
          action = Innate::Current.actions.last
          action.variables.each do |iv, value|
            instance_variable_set("@#{iv}", value)
          end')
      end
    end

    private

    def render
      instance.aspect_wrap(self) do
        self.value = instance.__send__(method, *params) if method
        self.view_value = File.read(view) if view
      end

      content_type, body = send(Innate.options.action.wish[wish] || :as_html)
      Current.response['Content-Type'] ||= content_type

      body
    end

    def as_html
      return 'text/html', wrap_in_layout{ fulfill_wish(view_value || value) }
    end

    def as_yaml
      require 'yaml'
      return 'text/yaml', (value || view_value).to_yaml
    end

    def as_json
      require 'json'
      return 'application/json', (value || view_value).to_json
    end

    def fulfill_wish(string)
      way = File.basename(view).gsub!(/.*?#{wish}\./, '') if view
      way ||= node.provide[wish] || node.provide['html']

      if way
        # Rack::Mime.mime_type(".#{wish}", 'text/html')
        View.get(way).render(self, string)
      else
        raise "No way!"
      end
    end

    def wrap_in_layout
      return yield unless layout

      action = dup
      action.view, action.method = layout_view_or_method(*layout)
      action.layout = nil
      action.sync_variables(self)
      action.variables[:content] = yield
      action.call
    end

    def layout_view_or_method(name, arg)
      return arg, nil if name == :layout || name == :view
      return nil, arg
    end
  end
end
