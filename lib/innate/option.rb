# Name:
#   Options - Options storage
#
# Version:
#   2008.09.13
#
# Description:
#   Options is a simple configuration system, it provides sane namespacing of
#   options and easy retrieval.
#
#   All options can be iterated and retrieved from anywhere in your programs
#   without the use of nasty global variables.
#
# Usage:
#     Options.for :site do |site|
#       site.title = 'araiguma'
#
#       site.admin do |admin|
#         admin.name = 'manveru'
#         admin.pass = 'letmein'
#       end
#
#       site.db = 'sqlite'
#     end
#
#     site = Options.for(:site)
#     site.title       #=> 'araiguma'
#     site.admin.name  #=> 'manveru'
#     site.admin.title #=> 'araiguma'
#
#
#
# TODO:
#   * Serialization for: Marshal, YAML, JSON
#   * Real world testing
#   * More informative pretty_print and inspect
#   * Find a faster way to access, this implementation is even slower than
#     OpenStruct

module Innate
  class Options < BasicObject
    VERSION = '2008-09-05'
    SCOPE = {}

    def self.for(name)
      name = name.to_s
      yield(SCOPE[name] ||= new(name)) if block_given?
      SCOPE[name]
    end

    def self.each(name)
      SCOPE[name.to_s].__hash.each do |key, value|
        yield(key, value)
      end
    end

    attr_accessor :__name, :__hash

    def initialize(name)
      @__name = name
      @__hash = {}
    end

    def [](key)
      @__hash[key.to_s]
    end

    def []=(key, value)
      @__hash[key.to_s] = value
    end

    # NOTE: 1.9 insists on '::Innate::Options', probably some kind of magic that would be
    #       performed by const_missing doesn't apply for BasicObject
    def method_missing(meth, *args, &block)
      meth = meth.to_s

      if meth =~ /:/
        # can only be issued by __send__, but one cannot be careful enough
        raise "':' is not allowed in a key"
      elsif meth =~ /^(.+)=$/
        SCOPE.delete("#@__name:#$1")
        self[$1] = args.first
      elsif block
        self[meth] = ::Innate::Options.for("#@__name:#{meth}", &block)
      else
        splat = @__name.split(':')

        splat.size.downto(1) do |n|
          key = splat[0, n] * ':'
          value = SCOPE[key][meth]

          unless value.nil?
            code = "def %s; SCOPE[%p][%p]; end" % [meth, key, meth]
            self.class.class_eval("def %s; SCOPE[%p][%p]; end" % [meth, key, meth])
            return value
          end
        end

        return nil
      end
    end

    # BasicObject doesn't have #class
    # This is a major problem when doing subclassing...

    def class
      Options
    end

    def to_hash
      @__hash
    end

    def pretty_print(q)
      q.pp_hash @__hash
    end

    def inspect
      @__hash.inspect
    end
  end
end
