module Innate
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

    def ancestral_trait
      ancs = respond_to?(:ancestors) ? ancestors : self.class.ancestors
      ancs.reverse.inject({}){|s,v|
        v.respond_to?(:trait) ? s.update(v.trait) : s
      }.merge(trait)
    end
  end
end
