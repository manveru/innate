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

  # NOTE: 1.9 insists on '::Options', probably some kind of magic that would be
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
      self[meth] = ::Options.for("#@__name:#{meth}", &block)
    else
      splat = @__name.split(':')

      splat.size.downto(1) do |n|
        value = SCOPE[splat[0, n] * ':'][meth]

        return value unless value.nil?
      end

      return nil
    end
  end

  def pretty_print(q)
    q.pp_hash @__hash
  end

  def inspect
    @__hash.inspect
  end
end

__END__

require 'bacon'
Bacon.extend(Bacon::TestUnitOutput)
Bacon.summary_on_exit

describe Options do
  should 'create scope' do
    Options.for :site do |site|
      site.title = 'araiguma'

      site.admin do |admin|
        admin.name = 'manveru'
        admin.pass = 'letmein'
      end

      site.db = 'sqlite'
    end

    Options.for(:site).title.should == 'araiguma'
  end

  should 'inherit scope' do
    Options.for(:site).admin.title.should == 'araiguma'
  end

  should 'access scope by for' do
    Options.for(:site).admin.name.should == 'manveru'
    Options.for('site:admin').name.should == 'manveru'
  end

  should 'replace scope with value' do
    Options.for(:site).db = 1
    Options.for(:site).db.should == 1
    Options::SCOPE['site:db'].should == nil
  end

  should 'replace value with scope' do
    Options.for(:site).db do |db|
      db.logging = true
    end

    Options.for(:site).db.logging.should == true
  end

  should 'iterate options' do
    expect = %w[admin db title]

    Options.each(:site) do |key, value|
      expect.delete key
    end

    expect.should.be.empty
  end
end

__END__

require 'ostruct'
require 'benchmark'

Options.for :a do |a|
  a.x = 1
end

$os = OpenStruct.new(:x => 1)

def bench_options
  Options.for('a')['x']
end

def bench_ostruct
  $os.x
end

Benchmark.bmbm(10) do |b|
  n = 100_000
  b.report('Options    :'){ n.times{ bench_options } }
  b.report('OpenStruct :'){ n.times{ bench_ostruct } }
  b.report('empty      :'){ n.times{ nil } }
end
