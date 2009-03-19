module Innate
  # Traited helps you doing configuration similar to class variables.
  #
  # It's built on a simple Hash, where keys are objects and the values the
  # configuration.
  # By using {Traited#ancestral_trait} you will get nicely inherited
  # configuration, where keys later in the ancestors will take precedence.
  #
  # @example usage
  #
  #   class Foo
  #     include Innate::Traited
  #     trait :hello => 'Hello'
  #
  #     def initialize
  #       trait :hello => 'World!'
  #     end
  #
  #     def show
  #       [class_trait[:hello], trait[:hello], ancestral_trait[:hello]]
  #     end
  #   end
  #
  #   Foo.trait[:hello] # => "Hello"
  #   foo = Foo.new
  #   foo.trait[:hello] # => "World!"
  #   foo.show          # => ["Hello", "World!", "World!"]
  module Traited
    TRAITS = {}

    def self.included(into)
      into.extend(self)
    end

    def trait(hash = nil)
      if hash
        TRAITS[self] ||= {}
        TRAITS[self].merge!(hash)
      else
        TRAITS[self] || {}
      end
    end

    # Builds a trait from all the ancestors, closer ancestors overwrite distant
    # ancestors
    #
    # class Foo
    #   include Innate::Traited
    #   trait :one => :eins, :first => :erstes
    # end
    #
    # class Bar < Foo
    #   trait :two => :zwei
    # end
    #
    # class Foobar < Bar
    #   trait :three => :drei, :first => :overwritten
    # end
    #
    # Foobar.ancestral_trait
    # # => {:three => :drei, :two => :zwei, :one => :eins, :first => :overwritten}
    def ancestral_trait
      result = {}
      each_ancestral_trait{|trait| result.merge!(trait) }
      result
    end

    def ancestral_trait_values(key)
      result = []
      each_ancestral_trait{|trait| result << trait[key] if trait.key?(key) }
      result
    end

    def each_ancestral_trait
      ancs = respond_to?(:ancestors) ? ancestors : self.class.ancestors
      ancs.unshift(self)
      ancs.reverse_each{|anc| yield(TRAITS[anc]) if TRAITS.key?(anc) }
    end

    # trait for self.class if we are an instance
    def class_trait
      respond_to?(:ancestors) ? trait : self.class.trait
    end
  end
end
