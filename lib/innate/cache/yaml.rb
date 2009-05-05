require 'yaml/store'

module Innate
  class Cache
    # Keeps every cache in a separate file like this:
    # /tmp/innate-cache-yaml/delta-manveru-session.yaml
    #
    # The YAML cache is not safe for use between multiple processes, it is also
    # very slow compared to other caches, so generally the use of it is
    # discouraged.
    class YAML
      include Cache::API
      include Cache::FileBased

      STORE = ::YAML::Store
      DIR = 'innate-cache-yaml'
      EXT = '.yaml'
    end
  end
end
