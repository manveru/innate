require 'yaml/store'

module Innate
  class Cache
    # Keeps every cache in a separate file like this:
    #
    # /tmp/innate-cache-yaml/delta-manveru-session.yaml
    class YAML
      include Cache::API
      include Cache::FileBased

      STORE = ::YAML::Store
      DIR = 'innate-cache-yaml'
      EXT = '.yaml'
    end
  end
end
