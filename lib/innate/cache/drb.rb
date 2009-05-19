require 'drb'

module Innate
  module Cache

    # Cache utilizing a DRb server.
    #
    # You will need to run a corresponding DRb server to use this cache. The
    # example below is using a normal Hash, but it is recommended to use a
    # thread-safe alternative like SyncHash.
    #
    # @example usage of DRb server
    #   require 'drb'
    #
    #   URI = "druby://127.0.0.1:9069"
    #   CACHE = {}
    #
    #   $SAFE = 1 # disable eval and friends
    #
    #   DRb.start_service(URI, CACHE)
    #   DRb.thread.join
    #
    # Please note that on some Ruby implementations, access to Hash is not
    # atomic and you might need to lock around access to avoid race conditions.
    #
    # @example for all caches
    #   Innate.options.cache.default = Innate::Cache::DRb
    #
    # @example for sessions only
    #   Innate.options.cache.session = Innate::Cache::DRb
    class DRb
      include Cache::API

      OPTIONS = {:address => '127.0.0.1', :port => 9069}

      def cache_setup(*args)
        address, port = OPTIONS.values_at(:address, :port)
        @store = DRbObject.new(nil, "druby://#{address}:#{port}")
      end

      def cache_clear
        @store.clear
      end

      def cache_store(*args)
        super{|key, value| @store[key] = value }
      end

      def cache_fetch(*args)
        super{|key| @store[key] }
      end

      def cache_delete(*args)
        super{|key| @store.delete(key) }
      end
    end
  end
end
