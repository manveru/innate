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
      result = {}

      ancs = respond_to?(:ancestors) ? ancestors : self.class.ancestors
      ancs.reverse_each do |anc|
        result.update(anc.trait) if anc.respond_to?(:trait)
      end

      result.merge!(trait)
    end
  end
end
