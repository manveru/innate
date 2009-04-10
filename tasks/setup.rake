# Currently, Innate is not usable without Rack from the master branch head.
# Also, our specs now depend on the latest rack-test.
#
# In order to make setup simpler for folks, I'll put up some gemspecs on github
# and use their automatic building to provide development versions of these
# libraries as gems for easier deployment.
#
# Once the libraries are officially released in a usable state I'll switch
# dependencies to the official ones again.
#
# Please note that this makes running in environments that enforce their own
# Rack (like jruby-rack) still quite difficult, but should allow for easier
# development.
#
# Please be patient.

desc 'install dependencies'
task :setup do
  GemInstaller.new do
    gem 'bacon', '>= 1.0'
    gem 'json', '~> 1.1.3'

    gem 'manveru-rack-test', '> 0.1.0', :lib => 'rack-test'
    gem 'manveru-rack', '>= 0.9.9', :lib => 'rack'

    setup
  end
end
