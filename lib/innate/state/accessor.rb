module Innate
  # Simplify accessing Thread.current variables.
  #
  # Example:
  #
  #   class Foo
  #     include Innate::StateAccessor
  #     state_accessor :session
  #
  #     def calculate
  #       session[:num1] + session[:num2]
  #     end
  #   end
  #
  # Foo#calculate can now be called from anywhere in your application and it
  # will have direct access to the session in the current request/response
  # cycle in a thread-safe way without the need to explicitly pass the session
  # along.

  module StateAccessor

    # Iterate over the names and yield accordingly.
    # names are either objects responding to #to_sym or hashes.
    #
    # It's only used within this module to make the code readable.
    #
    # Used below.

    def self.each(*names)
      names.each do |name|
        if name.respond_to?(:to_hash)
          name.to_hash.each do |key, meth|
            yield(key.to_sym, meth.to_sym)
          end
        else
          key = meth = name.to_sym
          yield(key, meth)
        end
      end
    end

    # Combined state_writer and state_reader.
    # +initializer+ is a block that may be given and its result will be the new
    # value in case the method created by state_reader was never called before
    # and the value wasn't set before.
    #
    # Example:
    #
    #   state_accessor(:session)
    #   state_accessor(:user){ session[:user] }

    def state_accessor(*names, &initializer)
      state_writer(*names)
      state_reader(*names, &initializer)
    end

    # Writer accessor to Thread.current[key]=
    #
    #   Example:
    #
    #   class Foo
    #     include Innate::StateAccessor
    #     state_writer(:result)
    #
    #     def calculate
    #       self.result = 42
    #     end
    #   end
    #
    #   class Bar
    #     include Innate::StateAccessor
    #     state_reader(:result)
    #
    #     def calculcate
    #       result * result
    #     end
    #   end
    #
    #   Foo.new.calculate # => 42
    #   Bar.new.calculate # => 1764

    def state_writer(*names)
      StateAccessor.each(*names) do |key, meth|
        class_eval("def %s=(obj) Thread.current[%p] = obj; end" % [meth, key])
      end
    end

    # Reader accessor for Thread.current[key]
    #
    # Example:
    #
    #   class Foo
    #     include Innate::StateAccessor
    #     state_reader(:session)
    #     state_reader(:random){ rand(100_000) }
    #
    #     def calculate
    #       val1 = session[:num1] + session[:num2] + random
    #       val2 = session[:num1] + session[:num2] + random
    #       val1 == val2 # => true
    #     end
    #   end
    #
    # NOTE:
    #   If given +initializer+, there will be some performance impact since we
    #   cannot use class_eval and have to use define_method instead, we also
    #   have to check every time whether the initializer was executed already.
    #
    #   In 1.8.x the overhead of define_method is 3x that of class_eval/def
    #   In 1.9.1 the overhead of define_method is 1.5x that of class_eval/def
    #
    #   This may only be an issue for readers that are called a lot of times.

    def state_reader(*names, &initializer)
      StateAccessor.each(*names) do |key, meth|
        if initializer
          define_method(meth) do
            unless Thread.current.key?(key)
              Thread.current[key] = instance_eval(&initializer)
            else
              Thread.current[key]
            end
          end
        else
          class_eval("def %s; Thread.current[%p]; end" % [meth, key])
        end
      end
    end
  end
end
