module Innate
  class Cache
    # Memory cache is simply a Hash with the Cache::API, it's the reference
    # implementation for every other cache.

    class Memory < Hash
      include Cache::API
    end
  end
end
