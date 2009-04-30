module Innate
  # Cache manager and wrapper.
  #
  # Provides a convenient wrapper around caches to keep method name confusion
  # at a minimum while still having short and meaningful method names for every
  # cache instance.
  #
  # The default caching is specified in lib/innate.rb in the config section.
  # At the time of writing it defaults to Innate::Cache::Memory but can be
  # changed easily.
  #
  # Configuration has to be done before Innate::setup_dependencies is being
  # called.
  #
  # Configuration:
  #
  #   Innate::Cache.options do |cache|
  #     cache.names = [:session, :user]
  #     cache.session = Innate::Cache::Marshal
  #     cache.user = Innate::Cache::YAML
  #   end
  #
  # Usage for storing:
  #
  #   # Storing with a time to live (10 seconds)
  #   Innate::Cache.user.store(:manveru, "Michael Fellinger", :ttl => 10)
  #
  #   # Storing indefinitely
  #   Innate::Cache.user[:Pistos] = "unknown"
  #   # or without :ttl argument
  #   Innate::Cache.user.store(:Pistos, "unknown")
  #
  # Usage for retrieving:
  #
  #   # we stored this one for 10 seconds
  #   Innate::Cache.user.fetch(:manveru, 'not here anymore')
  #   # => "Michael Fellinger"
  #   sleep 11
  #   Innate::Cache.user.fetch(:manveru, 'not here anymore')
  #   # => "not here anymore"
  #
  #   Innate::Cache.user[:Pistos]
  #   # => "unknown"
  #   Innate::Cache.user.fetch(:Pistos)
  #   # => "unknown"
  #
  #
  # For more details and to find out how to implement your own cache please
  # read the documentation of Innate::Cache::API
  #
  # NOTE:
  #   * Some caches might expose their contents for everyone else on the same
  #     system, or even on connected systems. The rule as usual is, not to
  #     cache sensitive information.

  class Cache
    autoload :API,       'innate/cache/api'
    autoload :DRb,       'innate/cache/drb'
    autoload :YAML,      'innate/cache/yaml'
    autoload :Memory,    'innate/cache/memory'
    autoload :Marshal,   'innate/cache/marshal'
    autoload :FileBased, 'innate/cache/file_based'

    include Optioned

    options.dsl do
      o "Assign a cache to each of these names on Innate::Cache::setup",
        :names, [:session, :view]

      default "If no option for the cache name exists, fall back to this",
        Innate::Cache::Memory
    end

    attr_reader :name, :instance

    def initialize(name, klass = nil)
      @name = name.to_s.dup.freeze

      klass ||= options[@name.to_sym]
      @instance = klass.new

      @instance.cache_setup(
        ENV['HOSTNAME'],
        ENV['USER'],
        'pristine',
        @name
      )
    end

    # Add all caches from the options.
    #
    # @see Innate::setup_dependencies
    # @api stable
    # @return [Array] names of caches initialized
    # @author manveru
    def self.setup
      options.names.each{|name| add(name) }
    end

    # Add accessors for cache
    #
    # @param [Cache] cache
    def self.register(cache)
      key = cache.name
      source = "def self.%s() @%s; end
                def self.%s=(o) @%s = o; end" % [key, key, key, key]
      self.class_eval(source, __FILE__, __LINE__)

      self.send("#{key}=", cache)
    end

    def self.add(*names)
      names.each{|name| register(new(name)) }
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
