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
        action_found(action)
      else
        action_not_found
      end
    end

    def action_found(action)
      catch(:respond) do
        catch(:redirect) do
          response.write action.call
        end
      end
    end

    def action_not_found
      response.status = 404
      response.write 'Action not found'
    end

    def resolve(path)
      name, *exts = path.split('.')

      return unless action = find_action(name)

      action.options ||= {}
      action.variables ||= {}
      action.wish = exts.last || 'html'

      assign_layout(action)

      return action
    end

    def find_action(name)
      patterns_for(name){|name, params|
        view = find_view(name, params)
        method = find_method(name, params)

        next unless view or method

        Action.create(:node => self, :params => params,
                      :method => method, :view => view)
      }
    end

    # TODO:
    #   * Remove rescue, it just slows things down

    def find_method(name, params)
      expected_arity = params.size

      possible_methods(name) do |arity|
        return name if arity == expected_arity or arity < 0
      end

      return nil
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

      path = [app_root, app_view, view_root, file]

      return [] unless path.all?

      path = File.join(*path)
      exts = @provide.values.uniq
      Dir["#{path}.{#{exts*','}}"]
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
      possible = to_view(name)

      if possible.size > 1
        interp = [possible.size, name, params, possible]
        warn "%d views found for %s:%p : %p" % interp
      end

      possible.first
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

      app = Options.for('innate:app')
      app_root = app[:root]
      app_layout = app[:layout]

      path = [app_root, app_layout, file]
      path = File.join(*path)
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
