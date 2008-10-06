module Org
  class Scope
    attr_accessor :parent, :name, :scopes

    def initialize(name, options = {})
      @rules = []
      @name, @options = name, options
      @scopes = {}
    end

    def scope(name, options = {}, &block)
      scope = Scope.new(name, options)
      scope.parent = self
      yield @scopes[name] = scope
    end

    def rule(name, regex, options = {})
      @rules << Rule.new(name, regex, options)
    end

    def apply
      yield(self)
    end

    def step(state)
      @rules.find do |rule|
        rule.match(state)
      end
    end

    def inspect
      "<Scope #{name}>"
    end
  end
end
