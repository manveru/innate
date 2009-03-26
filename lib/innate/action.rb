module Innate
  ACTION_MEMBERS = [ :node, :method, :params, :view, :layout, :instance, :exts,
    :wish, :options, :variables, :value, :view_value, :engine ]

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
      Current.actions << self
      render
    ensure
      Current.actions.delete(self)
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

      instance.instance_variables.each{|iv|
        iv_value = instance.instance_variable_get(iv)
        iv_name = iv.to_s[1..-1]
        self.variables[iv_name.to_sym] = iv_value
      }

      from_action
    end

    COPY_VARIABLES = '
      STATE[:action_variables].each do |iv, value|
        instance_variable_set("@#{iv}", value)
      end'.strip.freeze

    # Copy Action#variables as instance variables into the given binding.
    #
    # This relies on Innate::STATE, so should be thread-safe and doesn't depend
    # on Innate::Current::actions order.
    # So we avoid nasty business with Objectspace#_id2ref which may not work on
    # all ruby implementations and seems to cause other problems as well.
    #
    # @param [Binding #eval] binding
    # @return [NilClass] there is no indication of failure or success
    # @see View::ERB::render
    # @author manveru
    def copy_variables(binding = self.binding)
      return unless variables.any?

      STATE.sync do
        STATE[:action_variables] = self.variables

        eval(COPY_VARIABLES, binding)

        STATE[:action_variables] = nil
      end
    end

    def render
      self.instance = node.new
      self.variables[:content] ||= nil

      instance.wrap_action_call(self) do
        copy_variables # this might another position after all
        self.value = instance.__send__(method, *params) if method
        self.view_value = File.read(view) if view

        body, content_type = wrap_in_layout{
          engine.call(self, view_value || value || '') }
        options[:content_type] ||= content_type if content_type
        body
      end
    end

    def wrap_in_layout
      return yield unless layout

      action = dup
      action.view, action.method = layout_view_or_method(*layout)
      action.layout = nil
      action.sync_variables(self)
      body, content_type = yield
      action.variables[:content] = body
      return action.call, content_type
    end

    def layout_view_or_method(name, arg)
      [:layout, :view].include?(name) ? [arg, nil] : [nil, arg]
    end

    # Try to figure out a sane name for current action.
    def name
      File.basename((method || view).to_s).split('.').first
    end

    def valid?
      method || view
    end
  end
end
