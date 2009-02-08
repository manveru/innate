# What can be done with fewer assumptions is done in vain with more.
# -- William of Ockham (ca. 1285-1349)
#
# Name-space of Innate, just about everything goes in here.
#
# Exceptions are:
#
# * Logger::ColorFormatter
# * In 1.8, we define ::BasicObject
# * In 1.9, we define ::String#each
#
module Innate
  ROOT = File.expand_path(File.dirname(__FILE__))

  unless $LOAD_PATH.any?{|lp| File.expand_path(lp) == ROOT }
    $LOAD_PATH.unshift(ROOT)
  end

  # stdlib
  require 'pp'
  require 'set'
  require 'pathname'
  require 'digest/sha1'
  require 'ipaddr'
  require 'socket'
  require 'logger'
  require 'uri'

  # 3rd party
  require 'rack'

  # innate core patches
  require 'innate/core_compatibility/string'
  require 'innate/core_compatibility/basic_object'

  # innate core
  require 'innate/version'
  require 'innate/traited'
  require 'innate/cache'
  require 'innate/node'
  require 'innate/options'
  require 'innate/log'
  require 'innate/state'
  require 'innate/trinity'
  require 'innate/current'
  require 'innate/mock'
  require 'innate/adapter'
  require 'innate/action'
  require 'innate/helper'
  require 'innate/view'
  require 'innate/session'
  require 'innate/session/flash'
  require 'innate/dynamap'
  require 'innate/route'

  # innate lib/rack
  require 'rack/reloader'
  require 'rack/middleware_compiler'

  extend Trinity

  # This constant holds a couple of common middlewares and allows for easy
  # addition of new ones.
  # The Proc to use is determined by the value of options.mode.
  # The Proc value is passed to setup_middleware if no block is given to
  # Innate::start.
  #
  # A quick overview over the middleware used here:
  #
  #   * Rack::CommonLogger
  #     Logs a line in Apache common log format or <tt>rack.errors</tt>.
  #
  #   * Rack::ShowExceptions
  #     Catches all exceptions raised from the app it wraps. It shows a useful
  #     backtrace with the sourcefile and clickable context, the whole Rack
  #     environment and the request data.
  #     Be careful when you use this on public-facing sites as it could reveal
  #     information helpful to attackers.
  #
  #   * Rack::ShowStatus
  #     Catches all empty responses the app it wraps and replaces them with a
  #     site explaining the error.
  #     Additional details can be put into <tt>rack.showstatus.detail</tt> and
  #     will be shown as HTML. If such details exist, the error page is always
  #     rendered, even if the reply was not empty.
  #
  #   * Rack::ConditionalGet
  #     Middleware that enables conditional GET using If-None-Match and
  #     If-Modified-Since. The application should set either or both of the
  #     Last-Modified or Etag response headers according to RFC 2616. When
  #     either of the conditions is met, the response body is set to be zero
  #     length and the response status is set to 304 Not Modified.
  #
  #   * Rack::Head
  #     Removes the body of the response for HEAD requests.
  #
  #   * Rack::Reloader
  #     Pure ruby source reloader, runs on every request with a configurable
  #     cooldown period.
  #
  #   * Rack::Lint
  #     Rack::Lint validates your application and the requests and responses
  #     according to the Rack spec.
  #
  # Note that `m.innate` takes away most of the boring part and leaves it up to
  # you to select your middleware in your application.
  #
  # `m.innate` expands to:
  #
  #   use Rack::Cascade.new([
  #     Rack::File.new('public'),
  #     Innate::Current.new(
  #       Rack::Cascade.new([
  #         Innate::Rewrite.new(Innate::DynaMap),
  #         Innate::Route.new(Innate::DynaMap)])))
  #
  # @see Rack::MiddlewareCompiler
  MIDDLEWARE = {
    :dev => lambda{|m|
      m.use(Rack::Lint, Rack::CommonLogger, Rack::ShowExceptions,
            Rack::ShowStatus, Rack::ConditionalGet, Rack::Head, Rack::Reloader)
      m.innate },
    :live => lambda{|m|
      m.use(Rack::CommonLogger, Rack::ShowStatus, Rack::ConditionalGet,
            Rack::Head)
      m.innate }
  }

  module SingletonMethods
    def start(parameter = {}, &block)
      options[:app][:root] = go_figure_root(parameter, caller)
      parameter.reject!{|k, v| [:root, :file].include?(k) }
      options.merge!(parameter)

      setup_dependencies
      setup_middleware(&block)

      return if options.started
      options.started = true

      trap(options[:trap]){ stop(10) } if options[:trap]

      start!(options)
    end

    def start!(options = Innate.options)
      Adapter.start(middleware(:innate), options)
    end

    def stop(wait = 3)
      Log.info("Shutdown Innate within #{wait} seconds")
      Timeout.timeout(wait){ exit }
    ensure
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

    # Set the default middleware for applications.
    def setup_middleware(&block)
      mode = options.mode
      block ||= MIDDLEWARE[mode]
      raise("No Middleware for mode: %p found" % mode) unless block

      middleware(:innate, &block)
    end

    # Pass the +env+ to this method and it will be sent to the appropriate
    # middleware called +mw+.
    # Tries to avoid recursion.

    def call(env, mw = :innate)
      this_file = File.expand_path(__FILE__)
      count = 0
      caller_lines(caller){|f, l, m| count += 1 if f == this_file }

      raise("Recursive loop in Innate::call") if count > 10

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
      if o_file = options[:file]
        return File.dirname(o_file)
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

  extend SingletonMethods
end
