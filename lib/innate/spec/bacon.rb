begin; require 'rubygems'; rescue LoadError; end

require 'bacon'
require 'rack/test'
require File.expand_path('../../', __FILE__) unless defined?(Innate)

Bacon.summary_on_exit

module Innate
  # minimal middleware, no exception handling
  middleware(:spec){|m| m.innate }

  # skip starting adapter
  options.started = true
  options.mode = :spec
end

shared :rack_test do
  Innate.setup_dependencies
  extend Rack::Test::Methods

  def app; Innate.middleware; end
end

shared :mock do
  warn 'behaves_like(:mock) is deprecated, use behaves_like(:rack_test) instead'
  behaves_like :rack_test
end
