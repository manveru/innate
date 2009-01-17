module Innate
  class Cache

    # This is the API every Cache has to conform to.
    #
    # The default behaviour is tailored for the Memory cache, override any
    # behaviour as you need.
    #
    # +key+ may be a String or Symbol
    # +value+ is a Hash of serializable (as according to Marshal) objects
    #
    # Every cache instance has to respond to:
    #
    #   ::new()
    #   #cache_setup(hostname, username, appname, cachename)
    #   #cache_clear()
    #   #cache_delete(*keys)
    #   #cache_fetch(key, default = nil)
    #   #cache_store(key, value, options = {})
    #
    # We are prefixing cache_ to make the intent clear and implementation
    # easier, as there may be existing behaviour associated with the
    # non-prefixed version.
    #
    # Also note that we create one instance per cache name-space.
    module API
      # Executed after #initialize and before any other method.
      #
      # Some parameters identifying the current process will be passed so
      # caches that act in one global name-space can use them as a prefix.
      #
      # Treat all arguments as Strings.
      #
      # +hostname+  the hostname of the machine.
      # +username+  user executing this process.
      # +appname+   identifier for the application being executed.
      # +cachename+ name-space of the cache, like 'session' or 'action'
      def cache_setup(hostname, username, appname, cachename)
      end

      # Remove all key/value pairs from the cache.
      # Should behave as if #delete had been called with all +keys+ as argument.
      def cache_clear
        clear
      end

      # Remove the corresponding key/value pair for each key passed.
      # If removing is not an option it should set the corresponding value to nil.
      #
      # If only one key was deleted, answer with the corresponding value.
      # If multiple keys were deleted, answer with an Array containing the values.
      def cache_delete(key, *keys)
        if keys.empty?
          if value = yield(key)
            value[:value]
          end
        else
          [key, *keys].map{|k| cache_delete(k) }
        end
      end

      # Answer with the value associated with the +key+, +nil+ if not found or
      # expired.
      def cache_fetch(key, default = nil)
        value = default

        if entry = yield(key)
          if expires = entry[:expires]
            if expires > Time.now
              value = entry[:value]
            else
              cache_delete(key)
            end
          else
            value = entry[:value]
          end
        end

        return value
      end

      # Set +key+ to +value+.
      #
      # +options+ may be one of:
      #   :ttl => time to live in seconds if given in Numeric
      #                        infinite or maximum if not given
      #
      # Usage:
      #   Cache.value.store(:num, 3, :ttl => 20)
      #   Cache.value.fetch(:num) # => 3
      #   sleep 21
      #   Cache.value.fetch(:num) # => nil
      #
      def cache_store(key, value, options = {})
        ttl = options[:ttl]

        value_hash = {:value => value}
        value_hash[:expires] = Time.now + ttl if ttl

        yield(key, value_hash)

        return value
      end
    end
  end
end
