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
  # The Session instance is compatible with the specification of rack.session.
  #
  # Since the Time class is used to create the cookie expiration timestamp, you
  # will have to keep the ttl in a reasonable range.
  # The maximum value that Time can store on a 32bit system is:
  #   Time.at(2147483647) # => Tue Jan 19 12:14:07 +0900 2038
  #
  # The default expiration time for cookies and the session cache was reduced
  # to a default of 30 days.
  # This was done to be compatible with the maximum ttl of MemCache. You may
  # increase this value if you do not use MemCache to persist your sessions.
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
        :expires, nil
      o "Time to live in seconds for session cookies and cache",
        :ttl, (60 * 60 * 24 * 30) # 30 days

      trigger(:expires){|v|
        self.ttl = v - Time.now.to_i
        Log.warn("Innate::Session.options.expires is deprecated, use #ttl instead")
      }
    end

    attr_reader :cookie_set, :request, :response, :flash

    def initialize(request, response)
      @request, @response = request, response
      @cookie_set = false
      @cache_sid = nil
      @flash = Flash.new(self)
    end

    # Rack interface

    def store(key, value)
      cache_sid[key] = value
    end
    alias []= store

    def fetch(key, value = nil)
      cache_sid[key]
    end
    alias [] fetch

    def delete(key)
      cache_sid.delete(key)
    end

    def clear
      cache.delete(sid)
      @cache_sid = nil
    end

    # Additional interface

    def flush(response = @response)
      return if !@cache_sid or @cache_sid.empty?

      flash.rotate!
      cache.store(sid, cache_sid, :ttl => options.ttl)
      set_cookie(response)
    end

    def sid
      @sid ||= cookie || generate_sid
    end

    private

    def cache_sid
      @cache_sid ||= cache[sid] || {}
    end

    def cookie
      @request.cookies[options.key]
    end

    def cache
      Innate::Cache.session
    end

    def set_cookie(response)
      return if @cookie_set || cookie

      @cookie_set = true
      response.set_cookie(options.key, cookie_value)
    end

    def cookie_value
      { :domain  => options.domain,
        :expires => (Time.now + options.ttl),
        :path    => options.path,
        :secure  => options.secure,
        :value   => sid }
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
