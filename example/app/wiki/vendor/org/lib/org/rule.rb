module Org
  class Rule
    DEFAULT = {
      :bol => false,
      :start => nil,
      :end => nil,
      :unscan => false,
    }

    attr_accessor :name, :regex

    def initialize(name, regex, options = {}, &block)
      @name, @regex, @block = name, regex, block
      @options = DEFAULT.merge(options)
    end

    def match(state)
      scope, parent, scanner = state.scope, state.parent, state.scanner
      return if @options[:bol] and not scanner.bol?

      return false unless scanner.scan(@regex)
      scanner.unscan if @options[:unscan]

      name = @options[:tag] || @name
      token = Token.new(name, scanner.captures, &@block)
      return true if @options[:ignore]

      if mode = @options[:start]
        # puts "Start #{mode}"
        state.scope = mode.is_a?(Scope) ? mode : scope.scopes[mode]
        parent << token
        state.parent = token
      elsif mode = @options[:end]
        # puts "End #{mode}"
        state.parent = parent.parent
        state.scope = scope.parent
      else
        parent << token
        return true
      end
    end
  end
end
