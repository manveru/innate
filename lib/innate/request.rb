module Innate
  # Subclass Rack::Request and add some convenient methods.
  class Request < Rack::Request
    def self.current
      Current.request
    end

    def [](value, *keys)
      return super(value) if keys.empty?
      [value, *keys].map{|k| super(k) }
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

    # Try to find out which languages the client would like to have.
    # Returns and array of locales from env['HTTP_ACCEPT_LANGUAGE].
    # e.g. ["fi", "en", "ja", "fr", "de", "es", "it", "nl", "sv"]

    def accept_language
      env['HTTP_ACCEPT_LANGUAGE'].to_s.split(/(?:,|;q=[\d.,]+)/)
    end
    alias locales accept_language

    ipv4 = %w[ 127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 169.254.0.0/16 ]
    ipv6 = %w[ fc00::/7 fe80::/10 fec0::/10 ::1 ]
    LOCAL = (ipv4 + ipv6).map{|a| IPAddr.new(a)} unless defined?(LOCAL)

    # Request is from a local network?
    # Checks both IPv4 and IPv6
    # Answer is true if the IP address making the request is from local network.
    # Optional argument address can be used to check any IP address.

    def local_net?(address = ip)
      addr = IPAddr.new(address)
      LOCAL.find{|range| range.include?(addr) }
    rescue ArgumentError => ex
      raise ArgumentError, ex unless ex.message == 'invalid address'
    end
  end
end
