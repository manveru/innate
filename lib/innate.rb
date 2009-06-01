# What can be done with fewer assumptions is done in vain with more.
# -- William of Ockham (ca. 1285-1349)
#
# Name-space of Innate, just about everything goes in here.
#
# The only exception is Logger::ColorFormatter.
#
module Innate
  ROOT = File.expand_path(File.dirname(__FILE__))

  unless $LOAD_PATH.any?{|lp| File.expand_path(lp) == ROOT }
    $LOAD_PATH.unshift(ROOT)
  end

  # stdlib
  require 'digest/sha1'
  require 'digest/sha2'
  require 'find'
  require 'ipaddr'
  require 'logger'
  require 'pathname'
  require 'pp'
  require 'set'
  require 'socket'
  require 'uri'

  # 3rd party
  require 'rack'

  # innate core
  require 'innate/version'
  require 'innate/traited'
  require 'innate/trinity'
  require 'innate/middleware_compiler'
  require 'innate/options/dsl'
  require 'innate/options/stub'
  require 'innate/dynamap'

  # innate full
  require 'innate/cache'
  require 'innate/node'
  require 'innate/options'
  require 'innate/log'
  require 'innate/state'
  require 'innate/current'
  require 'innate/mock'
  require 'innate/adapter'
  require 'innate/action'
  require 'innate/helper'
  require 'innate/view'
  require 'innate/session'
  require 'innate/session/flash'
  require 'innate/route'

  extend Trinity

  # Contains all the module functions for Innate, we keep them in a module so
  # Ramaze can simply use them as well.
  module SingletonMethods
    PROXY_OPTIONS = { :port => 'adapter.port', :host => 'adapter.host',
                      :adapter => 'adapter.handler' }
    # The method that starts the whole business.
    #
    # Call Innate.start after you defined your application.
    #
    # Usually, this is a blocking call and will not return until the adapter
    # has finished, which usually happens when you kill the application or hit
    # ^C.
    #
    # We do return if options.started is true, which indicates that all you
    # wanted to do is setup the environment and update options.
    #
    # @example usage
    #
    #   # passing options
    #   Innate.start :adapter => :mongrel, :mode => :live
    #
    #   # defining custom middleware
    #   Innate.start do |m|
    #     m.innate
    #   end
    #
    # @return [nil] if options.started is true
    # @yield [MiddlewareCompiler]
    # @param [Proc] block will be passed to {middleware!}
    #
    # @option param :host    [String]  ('0.0.0.0')
    #   IP address or hostname that we respond to - 0.0.0.0 for all
    # @option param :port    [Fixnum]  (7000)
    #   Port for the server
    # @option param :started [boolean] (false)
    #   Indicate that calls Innate::start will be ignored
    # @option param :adapter [Symbol]  (:webrick)
    #   Web server to run on
    # @option param :setup   [Array]   ([Innate::Cache, Innate::Node])
    #   Will send ::setup to each element during Innate::start
    # @option param :header  [Hash]    ({'Content-Type' => 'text/html'})
    #   Headers that will be merged into the response before Node::call
    # @option param :trap    [String]  ('SIGINT')
    #   Trap this signal to issue shutdown, nil/false to disable trap
    # @option param :state   [Symbol]  (:Fiber)
    #   Keep state in Thread or Fiber, fall back to Thread if Fiber not available
    # @option param :mode    [Symbol]  (:dev)
    #   Indicates which default middleware to use, (:dev|:live)
    def start(given_options = {}, &block)
      root = given_options.delete(:root)
      file = given_options.delete(:file)

      found_root = go_figure_root(caller, :root => root, :file => file)
      Innate.options.roots = [*found_root] if found_root

      # Convert some top-level option keys to the internal ones that we use.
      PROXY_OPTIONS.each{|k,v| given_options[v] = given_options.delete(k) }
      given_options.delete_if{|k,v| v.nil? }

      # Merge the user's given options into our existing set, which contains defaults.
      options.merge!(given_options)

      setup_dependencies
      middleware!(options.mode, &block) if block_given?

      return if options.started
      options.started = true

      signal = options.trap
      trap(signal){ stop(10) } if signal

      start!
    end

    def start!(mode = options[:mode])
      Adapter.start(middleware(mode))
    end

    def stop(wait = 3)
      Log.info("Shutdown within #{wait} seconds")
      Timeout.timeout(wait){ teardown_dependencies }
      Timeout.timeout(wait){ exit }
    ensure
      exit!
    end

    def setup_dependencies
      options[:setup].each{|obj| obj.setup if obj.respond_to?(:setup) }
    end

    def teardown_dependencies
      options[:setup].each{|obj| obj.teardown if obj.respond_to?(:teardown) }
    end

    # Treat Innate like a rack application, pass the rack +env+ and optionally
    # the +mode+ the application runs in.
    #
    # @param [Hash] env rack env
    # @param [Symbol] mode indicates the mode of the application
    # @default mode options.mode
    # @return [Array] with [body, header, status]
    # @author manveru
    def call(env, mode = options[:mode])
      middleware(mode).call(env)
    end

    def middleware(mode = options[:mode], &block)
      options[:middleware_compiler].build(mode, &block)
    end

    def middleware!(mode = options[:mode], &block)
      options[:middleware_compiler].build!(mode, &block)
    end

    def middleware_recompile(mode = options[:mode])
      options[:middleware_compiler]::COMPILED[mode].compile!
    end

    # @example Innate can be started by:
    #
    #   Innate.start :file => __FILE__
    #   Innate.start :root => File.dirname(__FILE__)
    #
    # Either setting will surpress the warning that might show up on startup
    # and tells you it couldn't find an explicit root.
    #
    # In case these options are not passed we will try to figure out a file named
    # `start.rb` in the process' working directory and assume it's a valid point.
    def go_figure_root(backtrace, options)
      if root = options[:root]
        root
      elsif file = options[:file]
        File.dirname(file)
      elsif File.file?('start.rb')
        Dir.pwd
      else
        root = File.dirname(backtrace[0][/^(.*?):\d+/, 1])
        Log.warn "No explicit root folder found, assuming it is #{root}"
        root
      end
    end
  end

  extend SingletonMethods

  # This sets up the default modes.
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
  middleware :dev do |m|
    m.apps(Rack::Lint, Rack::Head, Rack::ContentLength, Rack::CommonLogger,
           Rack::ShowExceptions, Rack::ShowStatus, Rack::ConditionalGet)
    m.use(Rack::Reloader, 2)
    m.innate
  end

  middleware :live do |m|
    m.apps(Rack::Head, Rack::ContentLength, Rack::CommonLogger,
           Rack::ShowStatus, Rack::ConditionalGet)
    m.innate
  end
end
