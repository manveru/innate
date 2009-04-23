module Innate
  module Helper

    # Provides before/after wrappers for actions
    #
    # This helper is essential for proper working of {Action#render}.
    module Aspect
      AOP = Hash.new{|h,k| h[k] = Hash.new{|hh,kk| hh[kk] = {} }}

      def self.included(into)
        into.extend(SingletonMethods)
        into.add_action_wrapper(5.0, :aspect_wrap)
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

      # This awesome piece of hackery implements action AOP.
      #
      # The so-called aspects are simply methods that may yield the next aspect
      # in the chain, this is similar to racks concept of middleware, but instead
      # of initializing with an app we simply pass a block that may be yielded
      # with the action being processed.
      #
      # This gives us things like logging, caching, aspects, authentication, etc.
      #
      # Add the name of your method to the trait[:wrap] to add your own method to
      # the wrap_action_call chain.
      #
      # @example adding your method
      #
      #   class MyNode
      #     Innate.node '/'
      #
      #     private
      #
      #     def wrap_logging(action)
      #       Innate::Log.info("Executing #{action.name}")
      #       yield
      #     end
      #
      #     trait[:wrap]
      #   end
      #
      #
      # methods may register
      # themself in the trait[:wrap] and will be called in left-to-right order,
      # each being passed the action instance and a block that they have to yield
      # to continue the chain.
      #
      # @param [Action] action instance that is being passed to every registered method
      # @param [Proc] block contains the instructions to call the action method if any
      #
      # @see Action#render
      # @author manveru
      def wrap_action_call(action, &block)
        wrap = SortedSet.new
        action.node.ancestral_trait_values(:wrap).each{|sset| wrap.merge(sset) }
        head, *tail = wrap.map{|k,v| v }
        tail.reverse!
        combined = tail.inject(block){|s,v| lambda{ __send__(v, action, &s) } }
        __send__(head, action, &combined)
      end

      module SingletonMethods
        include Traited

        def before_all(&block)
          AOP[self][:before_all] = block
        end

        def before(*names, &block)
          names.each{|name| AOP[self][:before][name] = block }
        end

        def after_all(&block)
          AOP[self][:after_all] = block
        end

        def after(*names, &block)
          names.each{|name| AOP[self][:after][name] = block }
        end

        def wrap(*names, &block)
          before(*names, &block)
          after(*names, &block)
        end

        def add_action_wrapper(order, method_name)
          if wrap = trait[:wrap]
            wrap.merge(SortedSet[[order, method_name.to_s]])
          else
            trait :wrap => SortedSet[[order, method_name.to_s]]
          end
        end
      end
    end
  end
end
