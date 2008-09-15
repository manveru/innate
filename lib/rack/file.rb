require 'time'

module Rack
  # Rack::File serves files below the +root+ given, according to the
  # path info of the Rack request.
  #
  # Handlers can detect if bodies are a Rack::File, and use mechanisms
  # like sendfile on the +path+.

  class File
    attr_accessor :root
    attr_accessor :path

    def initialize(root)
      @root = F.expand_path(root)
    end

    def call(env)
      dup._call(env)
    end

    F = ::File

    def _call(env)
      if env["PATH_INFO"].include? ".."
        body = "Forbidden\n"
        size = body.respond_to?(:bytesize) ? body.bytesize : body.size
        return [403, {"Content-Type" => "text/plain","Content-Length" => size.to_s}, [body]]
      end

      @path = F.join(@root, Utils.unescape(env["PATH_INFO"]))

      if F.file?(@path) && F.readable?(@path)
        size = F.size?(@path) || F.read(@path).size
        ext = F.extname(@path)

        [200, {
           "Last-Modified"  => F.mtime(@path).httpdate,
           "Content-Type"   => Mime.mime_type(ext, 'text/plain'),
           "Content-Length" => size.to_s
         }, self]
      else
        body = "File not found: #{env["PATH_INFO"]}\n"
        size = body.respond_to?(:bytesize) ? body.bytesize : body.size
        [404, {"Content-Type" => "text/plain", "Content-Length" => size.to_s}, [body]]
      end
    end

    def each
      F.open(@path, "rb") { |file|
        while part = file.read(8192)
          yield part
        end
      }
    end
  end
end
