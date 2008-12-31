require 'pstore'

module Innate
  class Cache
    # Keeps every cache in a separate file like this:
    #
    # /tmp/innate-cache-marshal/delta-manveru-session.marshal
    class Marshal
      include Cache::API

      def cache_setup(*args)
        @prefix = args.compact.join('-')

        @dir = File.join(Dir.tmpdir, 'innate-cache-marshal')
        FileUtils.mkdir_p(@dir)

        @filename = File.join(@dir, @prefix + '.marshal')
        @store = ::PStore.new(@filename)
      end

      def cache_clear
        FileUtils.mkdir_p(@dir)
        FileUtils.rm_f(@filename)
        @store = ::PStore.new(@filename)
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
