module Innate
  # Subclass Rack::Request and add some convenient methods.
  class Request < Rack::Request
    def self.current
      Current.request
    end

    def [](value, *keys)
      return params[value.to_s] if keys.empty?
      [value, *keys].map{|k| params[k.to_s] }
    end

    def request_uri
      env['REQUEST_URI'] || env['PATH_INFO']
    end

    def subset(*keys)
      keys = keys.map{|k| k.to_s }
      params.reject{|k,v| not keys.include?(k) }
    end

    def domain(path = '/')
      scheme = env['rack.url_scheme'] || 'http'
      host = env['HTTP_HOST']
      URI("#{scheme}://#{host}#{path}")
    end

    def locales
      env['HTTP_ACCEPT_LANGUAGE'].to_s.split(/(?:,|;q=[\d.,]+)/)
    end
  end
end
