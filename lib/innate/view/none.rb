module Innate
  module View
    module None
      def self.call(action, string)
        return string.to_s, Response.mime_type
      end
    end
  end
end
