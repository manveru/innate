require 'yaml/store'

module Innate
  class Cache
    # Keeps every cache in a separate file like this:
    #
    # /tmp/innate-cache-yaml/delta-manveru-session.yaml
    class YAML
      include Cache::API

      def cache_setup(*args)
        p :args => args
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
        transaction do |store|
          store.delete(key)
        end
      end

      def [](key)
        transaction do |store|
          store[key]
        end
      end

      def []=(key, value)
        transaction do |store|
          store[key] = value
        end
      end

      def transaction(&block)
        Innate.sync{ @store.transaction(&block) }
      end
    end
  end
end
