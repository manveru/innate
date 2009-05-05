module Innate
  class Cache
    # Memory cache is simply a Hash with the Cache::API, it's the reference
    # implementation for every other cache and the default cache.
    class Memory < Hash
      include Cache::API

      def cache_store(*args)
        super{|key, value| self[key] = value }
      end

      def cache_fetch(*args)
        super{|key| self[key] }
      end

      def cache_delete(*args)
        super{|key| delete(key) }
      end
    end
  end
end
