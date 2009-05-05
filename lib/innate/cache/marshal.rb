require 'pstore'

module Innate
  class Cache
    # Keeps every cache in a separate file like this:
    # /tmp/innate-cache-marshal/delta-manveru-session.marshal
    #
    # The Marshal cache is not safe for use between multiple processes, it is
    # also slow compared to other caches, so generally the use of it is
    # discouraged.
    class Marshal
      include Cache::API
      include Cache::FileBased

      STORE = ::PStore
      DIR = 'innate-cache-marshal'
      EXT = '.marshal'
    end
  end
end
