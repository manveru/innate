module Innate
  class Cache

    # Used by caches that serialize their contents to the filesystem.
    module FileBased
      def cache_setup(*args)
        @prefix = args.compact.join('-')

        @dir = File.join(Dir.tmpdir, self.class::DIR)
        FileUtils.mkdir_p(@dir)

        @filename = File.join(@dir, @prefix + self.class::EXT)
        @store = self.class::STORE.new(@filename)
      end

      def cache_clear
        FileUtils.mkdir_p(@dir)
        FileUtils.rm_f(@filename)
        @store = self.class::STORE.new(@filename)
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
