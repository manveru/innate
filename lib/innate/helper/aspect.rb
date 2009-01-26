module Innate
  module Helper

    # Provides before/after wrappers for actions
    module Aspect
      AOP = Hash.new{|h,k| h[k] = Hash.new{|hh,kk| hh[kk] = {} }}

      def self.included(into)
        into.extend(SingletonMethods)
      end

      # Consider objects that have Aspect included
      def self.ancestral_aop(from)
        aop = {}
        from.ancestors.reverse.map{|anc| aop.merge!(AOP[anc]) if anc < Aspect }
        aop
      end

      def aspect_call(position, name)
        return unless aop = Aspect.ancestral_aop(self.class)
        return unless block_holder = aop[position]
        return unless block = block_holder[name.to_sym]
        block.call
      end

      def aspect_wrap(action)
        return yield unless method = action.method

        aspect_call(:before, method)
        yield
        aspect_call(:after, method)
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
    end
  end
end
