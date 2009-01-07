module Innate
  module Helper
    module Aspect
      DEFAULT << self

      AOP = Hash.new{|h,k| h[k] = Hash.new{|hh,kk| hh[kk] = {} }}

      def self.included(into)
        into.extend(SingletonMethods)
        into.__send__(:include, InstanceMethods)
      end

      # Consider objects that have Aspect included
      def self.ancestral_aop(from)
        aop = {}
        from.ancestors.reverse.map{|anc|
          next unless anc < Aspect
          aop.merge! AOP[anc]
        }
        aop
      end

      module SingletonMethods
        def before(name, &block)
          AOP[self][:before][name] = block
        end

        def after(name, &block)
          AOP[self][:after][name] = block
        end

        def wrap(name, &block)
          before(name, &block)
          after(name, &block)
        end
      end

      module InstanceMethods
        def call_aspect(position, name)
          aop = Aspect.ancestral_aop(self.class)

          block = aop[position][name]
          block.call if block
        end
      end
    end
  end
end
