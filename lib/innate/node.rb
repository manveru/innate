require 'set'

module Innate
  module Node
    def self.included(obj)
      obj.send(:include, Trinity, Helper)
      obj.extend(Trinity, self)
      obj.provide(:html => :html) # default provide
    end

    def map(location)
      Innate.map(location, self)
    end

    def provide(formats = {})
      @provide ||= {}

      if formats.respond_to?(:each_pair)
        formats.each_pair{|k,v| @provide[k.to_s] = v }
      elsif formats.respond_to?(:to_sym)
        formats[formats.to_sym.to_s] = formats
      elsif formats.respond_to?(:to_str)
        formats[formats.to_str] = formats
      else
        raise(ArgumentError, "provide(%p) is invalid parameter" % formats)
      end

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
        if valid_method?(meth, params)
          view = find_view(meth, params)
          Action.create(:node => self, :params => params,
                        :method => meth, :view => view)

        elsif view = find_view(meth, params)
          Action.create(:node => self, :params => params,
                        :view => view)
        end
      }

      return unless action

      action.options ||= {}
      action.variables ||= {}
      action.wish = exts.last || 'html'

      assign_layout(action)

      return action
    end

    # TODO:
    #   * Remove rescue, it just slows things down

    def valid_method?(name, params)
      expected_arity = params.size

      possible_methods(name) do |arity|
        return true if arity == expected_arity or arity < 0
      end

      return false
    rescue NameError => ex
      puts ex
      return false
    end

    # Takes a +name+ of the method to find and a block.
    # The block should take the arity of the found method.

    def possible_methods(name)
      [self, *(Helper::EXPOSE & ancestors)].each do |object|
        object.instance_methods(false).each do |im|
          next unless im.to_s == name
          yield object.instance_method(im).arity
        end
      end
    end

    def to_view(file)
      return [] unless file

      app = Options.for('innate:app')
      app_root = app[:root]
      app_view = app[:view]

      path = File.join(app_root, app_view, view_root, file)

      Dir["#{path}.*"]
    end

    def view_root(location = nil)
      if location
        @view_root = location
      else
        @view_root ||= Innate.to(self)
      end
    end

    def assign_view(action)
      action.view = to_view(name)
    end

    def find_view(name, params)
      to_view(name).first
    end

    def layout_root(location = nil)
      if location
        @layout_root = location
      else
        @layout_root ||= Innate.to(self)
      end
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
