module Innate
  class Cache

    # Used by caches that serialize their contents to the filesystem.
    # Right now we do not lock around write access to the file outside of the
    # process, that means that all FileBased caches are not safe for use if you
    # need more than one instance of your application.
    module FileBased
      attr_reader :filename

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

      def cache_store(*args)
        super{|key, value| transaction{|store| store[key] = value } }
      end

      def cache_fetch(*args)
        super{|key| transaction{|store| store[key] } }
      end

      def cache_delete(*args)
        super{|key| transaction{|store| store.delete(key) } }
      end

      def transaction(&block)
        Innate.sync{ @store.transaction(&block) }
      end
    end
  end
end
