module Innate
  # Provides a minimal DSL to describe options with defaults and metadata.
  #
  # The example below should demonstrate the major features, note that key
  # lookup wanders up the hierarchy until there is a match found or the parent
  # of the Options class is itself, in which case nil will be returned.
  #
  # Usage:
  #
  #   class Calculator
  #     @options = Options.new(:foo)
  #     def self.options; @options; end
  #
  #     options.dsl do
  #       o "Which method to use", :method, :plus
  #       o "Default arguments", :args, [1, 2]
  #       sub(:minus){ o("Default arguments", :args, [4, 3]) }
  #     end
  #
  #     def self.calculate(method = nil, *args)
  #       method ||= options[:method]
  #       args = args.empty? ? options[method, :args] : args
  #       self.send(method, *args)
  #     end
  #
  #     def self.plus(n1, n2)
  #       n1 + n2
  #     end
  #
  #     def self.minus(n1, n2)
  #       n1 - n2
  #     end
  #   end
  #
  #   Calculator.calculate
  #   # => 3
  #   Calculator.options[:method] = :minus
  #   # => :minus
  #   Calculator.calculate
  #   # => 1
  #   Calculator.calculate(:plus, 4, 5)
  #   # => 9
  #
  class Options
    def initialize(name, parent = self, &block)
      @name, @parent, = name, parent
      @hash = {}
      yield(self) if block_given?
    end

    # Shortcut for instance_eval
    def dsl(&block)
      instance_eval(&block) if block
      self
    end

    # Create a new Options instance with +name+ and pass +block+ on to its #dsl.
    # Assigns the new instance to the +name+ Symbol on current instance.
    def sub(name, &block)
      name = name.to_sym

      case found = @hash[name]
      when Options
        found.dsl(&block)
      else
        found = @hash[name] = Options.new(name, self).dsl(&block)
      end

      found
    end

    # Store an option in the Options instance.
    #
    # @param [#to_s]   doc   describing the purpose of this option
    # @param [#to_sym] key   used to access
    # @param [Object]  value may be anything
    # @param [Hash]    other optional Hash containing meta-data
    #                        :doc, :value keys will be ignored
    def o(doc, key, value, other = {}, &block)
      trigger = block || other[:trigger]
      convert = {:doc => doc.to_s, :value => value, :trigger => trigger}
      @hash[key.to_sym] = other.merge(convert)
    end

    # To avoid lookup on the parent, we can set a default to the internal Hash.
    # Parameters as in {Options#o}, but without the +key+.
    def default(doc, value, other = {})
      @hash.default = other.merge(:doc => doc, :value => value)
    end

    # Add a block that will be called when a new value is set.
    def trigger(key, &block)
      @hash[key.to_sym][:trigger] = block
    end

    # Try to retrieve the corresponding Hash for the passed keys, will try to
    # retrieve the key from a parent if no match is found on the current
    # instance. If multiple keys are passed it will try to find a matching
    # child and pass the request on to it.
    def get(key, *keys)
      if keys.empty?
        if value = @hash[key.to_sym]
          value
        elsif @parent != self
          @parent.get(key)
        else
          nil
        end
      elsif sub_options = get(key)
        sub_options.get(*keys)
      end
    end

    # Retrieve only the :value from the value hash if found via +keys+.
    def [](*keys)
      if value = get(*keys)
        value.is_a?(Hash) ? value[:value] : value
      end
    end

    # Assign new :value to the value hash on the current instance.
    #
    # TODO: allow arbitrary assignments
    def []=(key, value)
      if ns = @hash[key.to_sym]
        ns[:value] = value
        ns[:trigger].call(value) if ns[:trigger].respond_to?(:call)
      else
        raise(ArgumentError, "No key for %p exists" % [key])
      end
    end

    def method_missing(meth, *args)
      case meth.to_s
      when /^(.*)=$/
        self[$1] = args.first
      else
        self[meth]
      end
    end

    def merge!(hash)
      hash.each do |key, value|
        self[key] = value
      end
    end

    def to_hash
      @hash
    end

    def each(&block)
      @hash.each(&block)
    end

    def inspect
      @hash.inspect
    end

    def pretty_print(q)
      q.pp_hash @hash
    end
  end
end
