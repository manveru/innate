module Innate
  module Helper
    module SendFile
      # Not optimally performing but convenient way to send files by their
      # filename.
      def send_file(filename, content_type = nil)
        content_type ||= Rack::Mime.mime_type(::File.extname(filename))

        response.body = ::File.readlines(filename, 'rb')
        response['Content-Length'] = ::File.size(filename).to_s
        response['Content-Type'] = content_type
        response.status = 200

        throw(:respond, response)
      end
    end
  end
end
