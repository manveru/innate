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
        return unless block = at_position = aop[position]

        block = at_position[name.to_sym] unless at_position.is_a?(Proc)

        instance_eval(&block) if block
      end

      def aspect_wrap(action)
        return yield unless method = action.name

        aspect_call(:before_all, method)
        aspect_call(:before, method)
        result = yield
        aspect_call(:after, method)
        aspect_call(:after_all, method)

        result
      end

      module SingletonMethods
        def before_all(&block)
          AOP[self][:before_all] = block
        end

        def before(name, &block)
          AOP[self][:before][name] = block
        end

        def after_all(&block)
          AOP[self][:after_all] = block
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
