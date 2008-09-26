module Innate
  class Action < Struct.new(:node, :method, :params,
                            :view, :layout, :instance,
                            :exts, :wish, :options, :variables)
  end unless defined?(Innate::Action)

  class Action
    def self.create(hash)
      ms = members.map{|m| m.to_s }
      instance = new

      hash.each do |k,v|
        k = k.to_s
        instance[k] = v if ms.include?(k)
      end

      return instance
    end

    def call
      self.instance = node.new
      string = instance.send(method, *params) if method
      string = File.read(view) if view

      wrap_in_layout{ fulfill_wish(string) }
    end

    CONTENT_TYPE = {
      'sass' => 'text/css',
    }

    def fulfill_wish(string)
      if view
        way = File.basename(view).gsub!(/.*?#{wish}\./, '')
      end

      if way ||= node.provide[wish]
        node.response['content-type'] = content_type
        View.get(way).render(self, string)
      else
        raise
      end
    rescue => ex
      puts ex
    end

    def content_type
      return @content_type if defined?(@content_type)
      fallback = CONTENT_TYPE[wish] || 'text/plain'
      @content_type = Rack::Mime.mime_type(".#{wish}", fallback)
    end

    def wrap_in_layout
      if layout
        layout_action = dup
        layout_action.view = layout
        layout_action.layout = nil
        layout_action.variables[:content] = yield
        layout_action.call
      else
        yield
      end
    end
  end
end
