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
    TRAITS, ANCESTRAL_TRAITS, ANCESTRAL_VALUES = {}, {}, {}

    def self.included(into)
      into.extend(self)
    end

    def trait(hash = nil)
      if hash
        TRAITS[self] ||= {}
        result = TRAITS[self].merge!(hash)
        ANCESTRAL_VALUES.clear
        ANCESTRAL_TRAITS.clear
        result
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
      klass = self.kind_of?(Module) ? self : self.class
      ANCESTRAL_TRAITS[klass] ||=
        each_ancestral_trait({}){|hash, trait| hash.update(trait) }
    end

    def ancestral_trait_values(key)
      klass = self.kind_of?(Module) ? self : self.class
      cache = ANCESTRAL_VALUES[klass] ||= {}
      cache[key] ||= each_ancestral_trait([]){|array, trait|
        array << trait[key] if trait.key?(key) }
    end

    def each_ancestral_trait(obj)
      ancs = respond_to?(:ancestors) ? ancestors : self.class.ancestors
      ancs.unshift(self)
      ancs.reverse_each{|anc| yield(obj, TRAITS[anc]) if TRAITS.key?(anc) }
      obj
    end

    # trait for self.class if we are an instance
    def class_trait
      respond_to?(:ancestors) ? trait : self.class.trait
    end
  end
end
