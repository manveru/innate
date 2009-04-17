module Innate
  module Helper
    module SendFile
      # Not optimally performing but convenient way to send files by their
      # filename.
      #
      # I think we should remove this from the default helpers and move it into
      # Ramaze, the functionality is almost never used, the naming is ambigous,
      # and it doesn't use the send_file capabilities of frontend servers.
      #
      # So for now, I'll mark it for deprecation
      def send_file(filename, content_type = nil, content_disposition = nil)
        content_type ||= Rack::Mime.mime_type(::File.extname(filename))
        content_disposition ||= File.basename(filename)

        response.body = ::File.readlines(filename, 'rb')
        response['Content-Length'] = ::File.size(filename).to_s
        response['Content-Type'] = content_type
        response['Content-Disposition'] = content_disposition
        response.status = 200

        throw(:respond, response)
      end
    end
  end
end
