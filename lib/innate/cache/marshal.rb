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

      def cache_setup(*args)
        @prefix = args.compact.join('-')

        @dir = File.join(Dir.tmpdir, 'innate-cache-marshal')
        FileUtils.mkdir_p(@dir)

        @filename = File.join(@dir, @prefix + '.marshal')
        @store = ::PStore.new(@filename)
      end
    end
  end
end
