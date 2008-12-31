require 'yaml/store'

module Innate
  class Cache
    # Keeps every cache in a separate file like this:
    #
    # /tmp/innate-cache-yaml/delta-manveru-session.yaml
    class YAML
      include Cache::API

      def cache_setup(*args)
        @prefix = args.compact.join('-')

        @dir = File.join(Dir.tmpdir, 'innate-cache-yaml')
        FileUtils.mkdir_p(@dir)

        @filename = File.join(@dir, @prefix + '.yaml')
        @store = ::YAML::Store.new(@filename)
      end

      def cache_clear
        FileUtils.mkdir_p(@dir)
        FileUtils.rm_f(@filename)
        @store = ::YAML::Store.new(@filename)
      end

      def delete(key)
        transaction{|store| store.delete(key) }
      end

      def [](key)
        transaction{|store| store[key] }
      end

      def []=(key, value)
        transaction{|store| store[key] = value }
      end

      def transaction(&block)
        Innate.sync{ @store.transaction(&block) }
      end
    end
  end
end
