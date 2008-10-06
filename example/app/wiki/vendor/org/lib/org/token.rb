module Org
  class Token
    attr_accessor :name, :values, :options, :block, :childs, :parent

    def initialize(name, values, options = {}, &block)
      @name, @values, @options, @block = name, values, options, block
      @childs = []
    end

    def <<(token)
      token.parent = self
      @childs << token
    end

    def pretty_inspect
      {[name, values] => childs}.pretty_inspect
    end
    alias inspect pretty_inspect
  end
end
