module Innate
  module Helper
    module Redirect
      def respond(body, status = 200, header = {})
        response.write body
        response.status = status
        header['Content-Type'] ||= 'text/html'
        header.each{|k,v| response[k] = v }

        throw(:respond, response)
      end

      def respond!(body, status = 200, header = {})
        header['Content-Type'] ||= 'text/html'
        throw(:respond, Response.new(body, status, header))
      end

      # +target+ should be anything responding to #to_s.
      # To check or modify the URI the redirect will go to you may pass a
      # block, the result value of the block is ignored:
      #
      #   redirect("/"){|uri| uri.scheme = 'http' }
      #   redirect("/"){|uri| uri.host = 'secure.com' if uri.scheme =~ /s/ }
      #
      # +options+ may contain:
      #
      #   :scheme => "http" | "https" | "ftp" | ...
      #   :host   => "localhost" | "foo.com" | "123.123.123.123" | ...
      #   :port   => 7000 | "80" | 80 | ...
      #
      #   :status => 302 | 300 | 303 | ...
      #   :body   => "This is a redirect, hold on while we teleport" | ...
      #
      #   :raw!   => true | false | nil | ...
      #
      # Note that all options are optional and you may just pass a +target+.

      def redirect(target, options = {})
        target = target.to_s

        case target
        when /^http/, /^\//
          uri = URI(target)
        else
          uri = URI("/#{target}")
        end

        uri.scheme ||= options[:scheme] || request.scheme
        uri.host   ||= options[:host]   || request.host
        uri.port   ||= options[:port]   || request.port

        uri = URI(uri.to_s)

        yield(uri) if block_given?

        raw_redirect(uri, options)
      end

      def raw_redirect(target, options = {}, &block)
        header = response.header.merge('Location' => target.to_s)
        status = options[:status] || 302
        body   = options[:body] || redirect_body(target)

        Log.debug "Redirect to: #{target}"
        throw(:redirect, Response.new(body, status, header, &block))
      end

      def redirect_body(target)
        "You are being redirected, please follow this link to: " +
          "<a href='#{target}'>#{h target}</a>!"
      end

      def redirect_referrer(fallback = '/')
        if referer = request.referer and url = request.url
          referer_uri, request_uri = URI(referer), URI(url)

          redirect(referer) unless referer_uri == request_uri
        end

        redirect(fallback)
      end
      alias redirect_referer redirect_referrer
    end
  end
end
