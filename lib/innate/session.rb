module Innate

  # Mostly ported from Ramaze, but behaves lazy, no session will be created if
  # no session is used.
  #
  # The way we do it is to keep session data in memory until #flush is called,
  # at which point it will be persisted completely into the cache, no question
  # asked.
  #
  # NOTE:
  #   * You may store anything in here that you may also store in the
  #     corresponding store, usually it's best to keep it to things that are
  #     safe to Marshal.

  class Session
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
      return unless @cache_sid
      return if @cache_sid.empty?

      flash.rotate!
      cache[sid] = cache_sid
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

    def options
      Innate.options[:session]
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

    def entropy
      [ srand, rand, Time.now.to_f, rand, $$, rand, object_id ]
    end

    def generate_sid
      begin
        sid = Digest::SHA1.hexdigest(entropy.join)
      end while cache[sid]

      return sid
    end
  end
end
