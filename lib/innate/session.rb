module Innate

  # Mostly ported from Ramaze, but behaves lazy, no session will be created if
  # no session is used.

  class Session
    def initialize(request, response)
      @request, @response = request, response
      @cookie_set = false
    end

    def []=(key, value)
      set_cookie
      cache[sid] ||= {}
      cache[sid][key] = value
    end

    def [](key)
      cache[sid] ||= {}
      cache[sid][key]
    end

    def cookie
      @request.cookies[options.key]
    end

    def clear
      cache.delete(sid)
    end

    def sid
      @sid ||= cookie || generate_sid
    end

    def options
      Options.for('innate:session')
    end

    def cache
      Innate::Cache.session
    end

    private

    def set_cookie
      return if @cookie_set or cookie
      @cookie_set = true
      @response.set_cookie(options.key, cookie_value)
    end

    def cookie_value
      { :value   => sid,
        :domain  => options.domain,
        :path    => options.path,
        :secure  => options.secure,
        :expires => options.expires }
    end

    def entropy
      [ rand, Time.now.to_f, rand, $$, rand, object_id ]
    end

    def generate_sid
      begin
        sid = Digest::SHA1.hexdigest(entropy.join)
      end while cache[sid]

      return sid
    end
  end
end
