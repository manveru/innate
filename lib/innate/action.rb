module Innate
  ACTION_MEMBERS = [ :node, :instance, :method, :params, :method_value, :view,
    :view_value, :layout, :wish, :options, :variables, :engine, :path ]

  class Action < Struct.new(*ACTION_MEMBERS)
    # Create a new Action instance.
    # Note that the default cannot be a constant as assigning the value objects
    # to the struct would modify them and might lead to bugs due to persisting
    # action contents.
    #
    # @param [Hash, #to_hash] hash used to seed new Action instance
    # @return [Action] action with the given defaults from hash
    # @api stable
    # @author manveru
    def self.create(hash = {})
      default = {:options => {}, :variables => {}, :params => []}
      new(*default.merge(hash.to_hash).values_at(*ACTION_MEMBERS))
    end

    def merge!(hash)
      hash.each_pair{|key, value| send("#{key}=", value) }
      self
    end

    # Call the Action instance, will insert itself temporarily into
    # Current.actions during the render operation so even in nested calls one
    # can still access all other Action instances.
    # Will initialize the assigned node and call Action#render
    #
    # @return [String] The rendition of all nested calls
    # @see Action#render Node#action_found
    # @api stable
    # @author manveru
    def call
      Current.actions ? wrap_in_current{ render } : render
    end

    # @return [Binding] binding of the instance for this Action
    # @see Node#binding
    # @api stable
    # @author manveru
    def binding
      instance.binding
    end

    # Copy the instance variable names and values from given
    # from_action#instance into the Action#variables of the action this method
    # is called on.
    #
    # @param [Action #instance] from_action
    # @return [Action] from_action
    # @see Action#wrap_in_layout
    # @api unstable
    # @author manveru
    def sync_variables(from_action)
      instance = from_action.instance

      instance.instance_variables.each{|variable|
        name = variable.to_s[1..-1].to_sym
        self.variables[name] = instance.instance_variable_get(variable)
      }

      from_action
    end

    # Copy Action#variables as instance variables into the given object.
    # Defaults to copying the variables to self.
    #
    # @param [Object #instance_variable_set] object
    # @return [NilClass] there is no indication of failure or success
    # @see Action#render
    # @author manveru
    def copy_variables(object = instance)
      self.variables.each do |iv, value|
        object.instance_variable_set("@#{iv}", value)
      end
    end

    def render
      self.instance = instance = node.new
      self.variables[:content] ||= nil

      instance.wrap_action_call(self) do
        copy_variables
        self.method_value = instance.__send__(method, *params) if method
        self.view_value = View.read(view) if view

        body, content_type = wrap_in_layout{
          engine.call(self, view_value || method_value || '') }
        options[:content_type] ||= content_type if content_type
        body
      end
    end

    def wrap_in_layout
      layout ? dup.render_in_layout(&Proc.new) : yield
    end

    def render_in_layout
      self.view, self.method = layout_view_or_method(*layout)
      self.options[:is_layout] = true
      self.params = []
      self.layout = self.view_value = nil
      self.sync_variables(self)

      body, content_type = yield

      self.sync_variables(self)
      self.variables[:content] = body

      return call, content_type
    end

    def layout_view_or_method(name, arg)
      [:layout, :view].include?(name) ? [arg, nil] : [nil, arg]
    end

    def wrap_in_current
      Current.actions << self
      yield
    ensure
      Current.actions.delete(self)
    end

    # Try to figure out a sane name for current action.
    def name
      File.basename((method || view).to_s).split('.').first
    end

    # Path to this action, including params, with the mapping of the current
    # controller prepended.
    def full_path
      File.join(node.mapping, path)
    end

    def valid?
      node.needs_method? ? (method && view) : (method || view)
    end
  end
end
