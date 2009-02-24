require 'rubygems'
require 'innate'

class Demo
  Innate.node '/'

  def index
    'Hello, World!'
  end

  def empty
    response.status = 405
    ''
  end
end

Innate.start do |mw|
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

  # Start up the application
  mw.innate
end
