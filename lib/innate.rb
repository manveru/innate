# > What can be done with fewer assumptions is done in vain with more.
#   -- William of Ockham (ca. 1285-1349)

module Innate
  ROOT = File.expand_path(File.dirname(__FILE__))

  unless $LOAD_PATH.any?{|lp| File.expand_path(lp) == ROOT }
    $LOAD_PATH.unshift(ROOT)
  end
end

# stdlib
require 'pp'
require 'set'
require 'pathname'
require 'digest/sha1'
require 'ipaddr'
require 'socket'

# 3rd party
begin; require 'rubygems'; rescue LoadError; end
require 'rack'

module Rack
  autoload 'Profile', 'rack/profile'
end

# innate
require 'innate/core_compatibility/string'
require 'innate/core_compatibility/basic_object'

require 'innate/version'
require 'innate/options'
require 'innate/log'
require 'innate/state'
require 'innate/trinity'
require 'innate/current'
require 'innate/mock'
require 'innate/cache'
require 'innate/adapter'
require 'innate/action'
require 'innate/helper'
require 'innate/node'
require 'innate/view'
require 'innate/session'
require 'innate/dynamap'

require 'rack/reloader'
require 'rack/middleware_compiler'

module Innate
  extend Trinity

  module_function

  def start(parameter = {})
    return if options[:started]
    options[:started] = true

    setup_dependencies
    setup_middleware

    options[:app][:root] = go_figure_root(parameter, caller)
    options[:adapter] = parameter[:adapter] if parameter[:adapter]
    options[:port] = parameter.fetch(:port, options.port).to_i

    trap('INT'){ stop }

    Adapter.start(middleware(:innate), options)
  end

  def stop(wait = 0)
    Log.info "Shutdown Innate"
    exit!
  end

  def middleware(name, &block)
    Rack::MiddlewareCompiler.build(name, &block)
  end

  def middleware!(name, &block)
    Rack::MiddlewareCompiler.build!(name, &block)
  end

  def setup_dependencies
    options[:setup].each{|obj| obj.setup }
  end

  def setup_middleware
    middleware :innate do |m|
      # m.use Rack::CommonLogger # usually fast, depending on the output
      m.use Rack::ShowExceptions # fast
      m.use Rack::ShowStatus     # fast
      m.use Rack::Reloader       # reasonably fast depending on settings
      # m.use Rack::Lint         # slow, use only while developing
      # m.use Rack::Profile      # slow, use only for debugging or tuning
      m.use Innate::Current      # necessary

      m.cascade Rack::File.new('public'), Innate::DynaMap
    end
  end

  # Pass the +env+ to this method and it will be sent to the appropriate
  # middleware called +mw+.
  # Tries to avoid recursion.

  def call(env, mw = :innate)
    this_file = File.expand_path(__FILE__)
    count = 0
    caller_lines(caller){|f, l, m| count += 1 if f == this_file }

    raise RuntimeError, "Recursive loop in Innate::call" if count > 10

    middleware(mw).call(env)
  end

  # Innate can be started by:
  #
  #   Innate.start :file => __FILE__
  #   Innate.start :root => '/path/to/here'
  #
  # In case these options are not passed we will try to figure out a file named
  # `start.rb` in the backtrace and use the directory it resides in.
  #
  # TODO: better documentation and nice defaults, don't want to rely on a
  #       filename, bad mojo.

  def go_figure_root(options, backtrace)
    if file = options[:file]
      return File.dirname(file)
    elsif root = options[:root]
      return root
    end

    pwd = Dir.pwd

    return pwd if File.file?(File.join(pwd, 'start.rb'))

    caller_lines(backtrace) do |file, line, method|
      dir, file = File.split(File.expand_path(file))
      return dir if file == "start.rb"
    end

    return nil
  end

  # yields +file+, +line+, +method+
  def caller_lines(backtrace)
    backtrace.each do |line|
      if line =~ /^(.*?):(\d+):in `(.*)'$/
        file, line, method = $1, $2.to_i, $3
      elsif line =~ /^(.*?):(\d+)$/
        file, line, method = $1, $2.to_i, nil
      end

      yield(File.expand_path(file), line, method) if file and File.file?(file)
    end
  end
end
