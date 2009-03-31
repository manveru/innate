module Innate

  # In order to reset the body contents we also need to reset the length set by
  # Response#write - until I can submit a patch to Rack and the next release we
  # just do this.

  class Response < Rack::Response
    include Optioned

    options.dsl do
      o "Default headers, will not override headers already set",
        :headers, {'Content-Type' => 'text/html'}
    end

    attr_accessor :length

    def reset
      self.status = 200
      self.header.delete('Content-Type')
      body.clear
      self.length = 0
      self
    end

    def finish
      options.headers.each{|key, value| self[key] ||= value }
      super
    end
  end
end
