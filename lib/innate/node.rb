require 'set'

module Innate
  module Node
    def self.included(obj)
      obj.send(:include, Trinity)
      obj.extend(Trinity, self)
    end

    def map(location)
      Innate.map(location, self)
      map_view(location)
      map_layout(location)
    end

    def provide(formats = {})
      @provide ||= {}
      formats.each{|k,v| @provide[k.to_s] = v }
      @provide
    end

    def call(env)
      path = env['PATH_INFO']
      try_resolve(path)
      response.finish
    end

    def try_resolve(path)
      if action = resolve(path)
        catch(:respond){
          response.write action.call
          response.status = 200
        }
      else
        response.status = 404
        response.write 'Action not found'
      end
    end

    def resolve(path)
      name, *exts = path.split('.')

      action = patterns_for(name){|meth, params|
        find_method(meth, params) || find_view(meth, params)
      }

      return unless action

      action.options ||= {}
      action.variables ||= {}
      action.wish = exts.last || 'html'

      assign_layout(action)

      return action
    end

    # TODO:
    #   * Remove rescue, it just slows thins down

    def find_method(action, params)
      arity = self.instance_method(action).arity
      match = params.size

      if arity == match or arity < 0
        return Action.new(self, action, params)
      end
    rescue NameError
      nil
    end

    def map_view(location)
      @map_view = location
    end

    def to_view(file)
      return [] unless file
      o = Options.for(:innate)
      path = File.join(o.app_root, o.view_root, @map_view, file)
      Dir["#{path}.*"]
    end

    def find_view(name, params)
      views = to_view(name)
      return if views.empty?

      action = Action.new(self, nil, params)

      if views.size == 1
        action.view = views.first
      else # TODO
        action.view = views.first
      end

      return action
    end

    def map_layout(location)
      @map_layout = location
    end

    def to_layout(file)
      return [] unless file
      o = Options.for(:innate)
      path = File.join(o.app_root, o.layout_root, @map_layout, file)
      Dir["#{path}.*"]
    end

    def assign_layout(action)
      action.layout = to_layout(@layout).first
      return action
    end

    def layout(name = nil)
      @layout = name
    end

    def patterns_for(path)
      atoms = path.split('/')
      atoms.delete('')
      result = nil

      atoms.size.downto(0) do |len|
        action = atoms[0...len].join('__')
        params = atoms[len..-1]
        action = 'index' if action.empty?

        return result if result = yield(action, params)
      end

      return nil
    end
  end
end
