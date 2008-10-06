module Innate
  class Request < Rack::Request
    def [](value, *keys)
      return params[value.to_s] if keys.empty?
      [value, *keys].map{|k| params[k.to_s] }
    end
  end
end
