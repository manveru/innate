module Innate
  $LOAD_PATH.unshift File.dirname(File.expand_path(__FILE__))
  $LOAD_PATH.uniq!
  ROOT = File.expand_path(File.dirname(__FILE__))
end

require 'pp'

require 'innate/core_compatibility/string'
require 'innate/core_compatibility/fiber'
require 'innate/core_compatibility/basic_object'

require 'innate/util/state_accessor'

require 'innate/option'
require 'innate/state'
require 'innate/trinity'
require 'innate/current'
require 'innate/strategy'
require 'innate/mock'
require 'innate/adapter'
require 'innate/action'
require 'innate/node'
require 'innate/view'

require 'rack/reloader'
require 'rack/profile'
require 'rack/middleware_compiler'

module Innate
  extend Trinity

  @config = Options.for(:innate){|innate|
    innate.root = Innate::ROOT
    innate.view_root = 'view'
    innate.layout_root = 'layout'
    innate.started = false
    innate.adapter = :webrick
  }

  def self.start(options = {})
    return if @config.started

    @config.caller = app_root_from(caller)
    @config.app_root = File.dirname(@config.caller)
    @config.started = true
    @config.adapter = (options[:adapter] || @config.adapter).to_s

    trap('INT'){ stop }

    Rack::Handler.get(@config.adapter).run(middleware, :Port => 7000)
  end

  # nasty, horribly nasty and possibly b0rken, but it's a start
  def self.app_root_from(backtrace)
    caller_lines(backtrace) do |file, line, method|
      haystack = File.readlines(file)[line - 1]
      return file if haystack =~ /Innate\.start/
    end
  end

  # yield [file, line]
  def self.caller_lines(backtrace)
    backtrace.each do |line|
      if line =~ /^(.*?):(\d+):in `(.*)'$/
        file, line, method = $1, $2.to_i, $3
      elsif line =~ /^(.*?):(\d+)$/
        file, line, method = $1, $2.to_i, nil
      end

      yield(file, line, method) if file and File.file?(file)
    end
  end

  def self.stop(wait = 0)
    puts "Shutdown Innate"
    exit!
  end

  def self.middleware
    Rack::MiddlewareCompiler.build :innate do |c|
      c.use Rack::CommonLogger   # fast depending on the output
      c.use Rack::ShowExceptions # fast
      c.use Rack::ShowStatus     # fast
      c.use Rack::Reloader       # reasonably fast depending on settings
      c.use Rack::Lint           # slow, use only while developing
#       c.use Rack::Profile        # slow, use only for debugging or tuning
      c.use Innate::Current      # necessary

      c.cascade Rack::File.new('public'), Innate::DynaMap
    end
  end

  def self.map(location, node)
    DynaMap.map(location, node)
  end

  def self.call(env)
    if recursive?(caller)
      puts "recursive call"
      exit!
    else
      middleware.call(env)
    end
  end

  def self.recursive?(backtrace, max = 3)
    caller_lines(backtrace) do |file, line, method|
      p [file, line, method]
    end

    this_file = File.expand_path(__FILE__)
    caller.select{|line|
      this_file == File.expand_path(line[/^(.*):(\d+):in `(.*)'$/, 1].to_s)
    }.size >= max
  end

  class DynaMap
    MAP = {}
    CACHE = {}

    def self.call(env)
      CACHE[:map].call(env)
    end

    def self.map(location, node)
      MAP[location] = node
      CACHE[:map] = Rack::URLMap.new(MAP)
    end
  end
end
