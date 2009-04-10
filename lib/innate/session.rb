module Innate

  # Mostly ported from Ramaze, but behaves lazy, no session will be created if
  # no session is used.
  #
  # We keep session data in memory until #flush is called, at which point it
  # will be persisted completely into the cache, no question asked.
  #
  # You may store anything in here that you may also store in the corresponding
  # store, usually it's best to keep it to things that are safe to Marshal.
  #
  # The default time of expiration is *
  #
  #   Time.at(2147483647) # => Tue Jan 19 12:14:07 +0900 2038
  #
  # Hopefully we all have 64bit systems by then.

  class Session
    include Optioned

    options.dsl do
      o "Key for the session cookie",
        :key, 'innate.sid'
      o "Domain the cookie relates to, unspecified if false",
        :domain, false
      o "Path the cookie relates to",
        :path, '/'
      o "Use secure cookie",
        :secure, false
      o "Time of cookie expiration",
        :expires, Time.at((1 << 31) - 1)
    end

    attr_reader :cookie_set, :request, :response, :flash

    def initialize(request, response)
      @request, @response = request, response
      @cookie_set = false
      @cache_sid = nil
      @flash = Flash.new(self)
    end

    def []=(key, value)
      cache_sid[key] = value
    end

    def [](key)
      cache_sid[key]
    end

    def delete(key)
      cache_sid.delete(key)
    end

    def clear
      cache.delete(sid)
      @cache_sid = nil
    end

    def cache_sid
      @cache_sid ||= cache[sid] || {}
    end

    def flush(response = @response)
      return if !@cache_sid or @cache_sid.empty?

      flash.rotate!
      ttl = (Time.at(cookie_value[:expires]) - Time.now).to_i
      cache.store(sid, cache_sid, :ttl => ttl)
      set_cookie(response)
    end

    def sid
      @sid ||= cookie || generate_sid
    end

    def cookie
      @request.cookies[options.key]
    end

    def inspect
      cache.inspect
    end

    private

    def cache
      Innate::Cache.session
    end

    def set_cookie(response)
      return if @cookie_set || cookie

      @cookie_set = true
      response.set_cookie(options.key, cookie_value)
    end

    def cookie_value
      { :value   => sid,
        :domain  => options.domain,
        :path    => options.path,
        :secure  => options.secure,
        :expires => options.expires }
    end

    def generate_sid
      begin sid = sid_algorithm end while cache[sid]
      sid
    end

    begin
      require 'securerandom'
      def sid_algorithm; SecureRandom.hex(32); end
    rescue LoadError
      def sid_algorithm
        entropy = [ srand, rand, Time.now.to_f, rand, $$, rand, object_id ]
        Digest::SHA2.hexdigest(entropy.join)
      end
    end
  end
end
