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

require 'rack/directory'
require 'rack/file'
require 'rack/reloader'
require 'rack/profile'

module Innate
  extend Trinity

  @config = Options.for(:innate){|innate|
    innate.root = Innate::ROOT
    innate.view_root = 'view'
    innate.layout_root = 'layout'
    innate.started = false
  }

  def self.start(options = {})
    return if @config.started

    @config.caller = find_app_root(caller)
    @config.app_root = File.dirname(@config.caller)
    @config.started = true

    trap('INT'){ stop }

    Rack::Handler.get('thin').run(middleware, :Port => 7000)
  end

  # nasty, horribly nasty and possibly b0rken, but it's a start
  def self.find_app_root(caller)
    caller.each do |bt|
      if bt =~ /^(.*?):(\d+)/
        file, line = $1, $2.to_i
        File.open(file){|f|
          current = 1

          until line == current
            current += 1
            break unless f.gets
          end

          return File.expand_path(file) if f.gets =~ /Innate\.start/
        }
      end
    end

    nil
  end

  def self.stop(wait = 0)
    puts "Shutdown Innate"
    exit!
  end

  def self.middleware
    return @middleware if @middleware

    @middleware = Rack::Builder.new{
      use Rack::CommonLogger
      use Rack::ShowExceptions
      use Rack::ShowStatus
      use Rack::Reloader
      use Rack::Lint
      # use Rack::Profile
      use Innate::Current

      cascade = [Rack::File.new('public'), Innate::DynaMap]
      run Rack::Cascade.new(cascade)
    }
  end

  def self.middleware=(mw)
    @middleware = mw
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

  def self.recursive?(caller, max = 3)
    this_file = File.expand_path(__FILE__)
    caller.select{|line|
      this_file == File.expand_path(line[/^(.*):(\d+):in `(.*)'$/, 1].to_s)
    }.size >= max
  end

  class DynaMap
    MAP = {}

    def self.call(env)
      Rack::URLMap.new(MAP).call(env)
    end

    def self.map(location, node)
      MAP[location] = node
    end
  end
end
