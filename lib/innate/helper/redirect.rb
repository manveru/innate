module Innate
  module Helper
    module Redirect
      DEFAULT << self

      def respond(body, status, header)
        resopnse.write body
        response.status = status
        response.header = header

        throw(:respond)
      end

      def respond!(body, status, header)
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
        uri = URI(target.to_s)
        uri.scheme ||= options[:scheme] || request.scheme
        uri.host   ||= options[:host]   || request.host
        uri.port   ||= options[:port]   || request.port
        uri = URI(uri.to_s)

        yield(uri) if block_given?

        options[:raw!] ? raw_redirect!(uri, options) : raw_redirect(uri, options)
      end

      def raw_redirect(target, options = {})
        target = target.to_s

        response['Location'] = target
        response.status = options[:status] || 302
        response.write    options[:body]   || redirect_body(target)

        Log.debug "Redirect to: #{target}"
        throw(:redirect, response)
      end

      # Don't reuse the current response object

      def raw_redirect!(target, options = {}, &block)
        header = {'Location' => target}
        status = options[:status] || 302
        body   = options[:body] || redirect_body(target)

        Log.debug "Redirect to: #{target}"
        throw(:redirect, Response.new(body, status, header, &block))
      end

      def redirect_body(target)
        "You are being redirected, please follow this link to: " +
          "<a href='#{target}'>#{h target}</a>!"
      end

      def redirect_referrer
        redirect request.referer
      end
      alias redirect_referer redirect_referrer
    end
  end
end
