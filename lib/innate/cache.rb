module Innate
  # Cache manager and wrapper.
  #
  # Provides a convenient wrapper around caches to keep method name confusion
  # at a minimum while still having short and meaningful method names for every
  # cache instance.
  #
  # NOTE:
  #   * some caches might expose their contents for everyone else on the same
  #     system, or even on connected systems. The rule as usual is, not to
  #     cache sensitive information.

  class Cache
    autoload :API, 'innate/cache/api'
    autoload :YAML, 'innate/cache/yaml'
    autoload :Memory, 'innate/cache/memory'
    autoload :Marshal, 'innate/cache/marshal'

    attr_reader :name, :instance

    def initialize(name, klass = nil)
      @name = name.to_s.dup.freeze

      options = Innate.options

      klass ||= options.cache[@name] || options.cache.default
      @instance = klass.new

      @instance.cache_setup(
        options.env.host,
        options.env.user,
        options.app.name,
        @name
      )

      self.class.register(self)
    end

    def self.setup
      Innate.options.cache.names.each do |name|
        register(new(name))
      end
    end

    def self.register(cache)
      key = cache.name
      self.class_eval("def self.%s() @%s; end
                       def self.%s=(o) @%s = o; end" % [key, key, key, key])

      self.send("#{key}=", cache)
    end

    def clear
      instance.cache_clear
    end

    def delete(*keys)
      instance.cache_delete(*keys)
    end

    def fetch(key, default = nil)
      instance.cache_fetch(key, default)
    end
    alias [] fetch

    def store(key, value, options = {})
      instance.cache_store(key, value, options)
    end
    alias []= store
  end
end
