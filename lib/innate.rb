module Innate
  $LOAD_PATH.unshift File.dirname(File.expand_path(__FILE__))
  $LOAD_PATH.uniq!
  ROOT = File.expand_path(File.dirname(__FILE__))
end

require 'pp'
require 'set'

require 'innate/core_compatibility/string'
require 'innate/core_compatibility/basic_object'

require 'innate/option'
require 'innate/state'
require 'innate/trinity'
require 'innate/current'
require 'innate/mock'
require 'innate/adapter'
require 'innate/action'
require 'innate/helper'
require 'innate/node'
require 'innate/view'
require 'innate/session'

require 'rack/reloader'
require 'rack/profile'
require 'rack/middleware_compiler'

module Innate
  extend Trinity

  @config = Options.for(:innate){|innate|
    innate.root = Innate::ROOT
    innate.started = false
    innate.adapter = :webrick

    innate.header = {
      'Content-Type' => 'text/html',
      # 'Accept-Charset' => 'utf-8',
    }

    innate.redirect_status = 302

    innate.app do |app|
      app.root = '/'
      app.view = 'view'
      app.layout = 'layout'
    end

    innate.session do |session|
      session.key = 'innate.sid'
      session.domain = false
      session.path = '/'
      session.secure = false

      # The current value is a time at:
      #   2038-01-19 03:14:07 UTC
      # Let's hope that by then we get a better ruby with a better Time class
      session.expires = Time.at(2147483647)
    end
  }

  def self.start(options = {})
    return if @config.started

    config.caller = caller
    config.app.caller = who_called?(/Innate\.start/, caller)
    config.app.root = File.dirname(config.app.caller)
    config.started = true
    config.adapter = (options[:adapter] || @config.adapter).to_s

    trap('INT'){ stop }

    Rack::Handler.get(@config.adapter).run(middleware, :Port => 7000)
  end

  def self.config
    @config
  end

  # nasty, horribly nasty and possibly b0rken, but it's a start
  def self.who_called?(regexp, backtrace)

    caller_lines(backtrace) do |file, line, method|
      haystack = File.readlines(file)[line - 1]
      return file if haystack =~ regexp
    end

    return nil
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

  def self.at(location)
    DynaMap::MAP[location]
  end

  def self.to(node)
    DynaMap::MAP.invert[node]
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
#       p [file, line, method]
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
