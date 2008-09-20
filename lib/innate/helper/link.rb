module Innate
  module Helper
    module Link
      def r(name, hash = {})
        location = Innate.to(self)
        front = "#{location}/#{name}".squeeze('/')

        if hash.empty?
          URI(front)
        else
          query = hash.map{|k,v| "#{u k}=#{u v}" }.join(';')
          URI("#{front}?#{query}")
        end
      end

      def a(text, hash = {})
        href = hash[:href] || r(text, hash)
        "<a href='#{href}'>#{text}</a>"
      end
    end
  end
end
