require 'pstore'

module Innate
  class Cache
    # Keeps every cache in a separate file like this:
    #
    # /tmp/innate-cache-marshal/delta-manveru-session.marshal
    class Marshal
      include Cache::API
      include Cache::FileBased

      STORE = ::PStore
      DIR = 'innate-cache-marshal'
      EXT = '.marshal'
    end
  end
end
