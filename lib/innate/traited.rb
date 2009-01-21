module Innate
  module Traited
    TRAITS = Hash.new{|h,k| h[k] = {}}

    def self.included(into)
      into.extend(self)
    end

    def trait(hash = nil)
      hash ? TRAITS[self].update(hash) : TRAITS[self]
    end

    def ancestral_trait
      ancs = respond_to?(:ancestors) ? ancestors : self.class.ancestors
      ancs.reverse.inject({}){|s,v|
        v.respond_to?(:trait) ? s.update(v.trait) : s
      }.merge(trait)
    end
  end
end
