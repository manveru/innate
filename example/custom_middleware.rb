require 'innate'

class Demo
  include Innate::Node
  map '/'

  def index
    'Hello, World!'
  end

  def empty
    response.status = 405
    ''
  end
end

# Make sure you do this before Innate.start, otherwise you have to use
# Innate.middleware! to force a rebuild in the MiddlewareCompiler.
Innate.middleware :innate do |mw|
  # Makes sure all requests and responses conform to Rack protocol
  mw.use Rack::Lint

  # Avoid showing empty failure pages, give information when it happens.
  mw.use Rack::ShowStatus

  # Catch exceptions inside Innate and give nice status info
  mw.use Rack::ShowExceptions

  # Log access
  mw.use Rack::CommonLogger

  # Reload modified files before request
  mw.use Rack::Reloader

  # Initializes the Current objects: Request, Response, and Session
  mw.use Innate::Current

  # This will try to find a static file in /public first, and try DynaMap if
  # Rack::File returns a 404 status.
  mw.cascade Rack::File.new('public'), Innate::DynaMap
end

Innate.start
