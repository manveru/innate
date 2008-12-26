require 'set'

module Innate
  module Node
    def self.included(obj)
      obj.__send__(:include, Helper)
      obj.extend(Trinity, self)
      obj.provide(:html => :none) # provide .html with no interpolation
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
      path << '/' if path.empty?

      try_resolve(path)

      response.finish
    rescue Exception => exception
      Log.error(exception)
      raise(exception)
    end

    def try_resolve(path)
      if action = resolve(path)
        action_found(action)
      else
        action_not_found(path)
      end
    end

    def action_found(action)
      catch(:respond) do
        catch(:redirect) do
          response.write action.call
          response['Content-Type'] ||= action.content_type
        end
      end
    end

    # The default handler in case no action was found, kind of method_missing.
    # Must modify the response in order to have any lasting effect.
    #
    # Reasoning:
    # * We are doing this is in order to avoid tons of special error handling
    #   code that would impact runtime and make the overall API more
    #   complicated.
    # * This cannot be a normal action is that methods defined in Innate::Node
    #   will never be considered for actions.
    # * Also, you should not use #try_resolve to do the dispatching manually,
    #   as this may result in recursion until you get a SystemStackError
    #
    # To use a normal action with template do following:
    #
    #   class Hi
    #     include Innate::Node
    #     map '/'
    #
    #     def action_not_found(path)
    #       # No normal action, runs on bare metal
    #       action_found('/not_found')
    #     end
    #
    #     def not_found
    #       # Normal action
    #       "Sorry, I do not exist"
    #     end
    #   end

    def action_not_found(path)
      response.status = 404
      response['Content-Type'] = 'text/plain'
      response.write("Action not found at: %p" % path)
    end

    def resolve(path)
      name, *exts = path.split('.')
      wish = exts.last || 'html'

      find_action(name, wish)
    end

    def find_action(name, wish)
      patterns_for(name){|name, params|
        view = find_view(name, wish, params)
        method = find_method(name, params)

        next unless view or method

        layout = to_layout(@layout).first

        Action.create(:node => self, :params => params, :wish => wish,
                      :method => method, :view => view, :options => {},
                      :variables => {}, :layout => layout)
      }
    end

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

    def to_view(file, wish)
      return [] unless file

      app = Options.for('innate:app')
      app_root = app[:root]
      app_view = app[:view]

      path = [app_root, app_view, view_root, file]

      return [] unless path.all?

      path = File.join(*path)
      exts = [@provide[wish], *@provide.keys].flatten.uniq.join(',')

      glob = "#{path}.{#{wish}.,#{wish},}{#{exts},}"

      Dir[glob].uniq
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

    def find_view(name, wish, params)
      possible = to_view(name, wish)

      if possible.size > 1
        interp = [possible.size, name, params, possible]
        Log.warn "%d views found for %s:%p : %p" % interp
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

      path = [app[:root], app[:layout], file]
      path = File.join(*path)
      Dir["#{path}.*"]
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
