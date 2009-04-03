require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'time'
require 'date'

specs =  Dir['spec/{innate,example}/**/*.rb']
specs -= Dir['spec/innate/cache/common.rb']
PROJECT_SPECS = specs
PROJECT_MODULE = 'Innate'

GEMSPEC = Gem::Specification.new{|s|
  s.name         = 'innate'
  s.author       = "Michael 'manveru' Fellinger"
  s.summary      = "Powerful web-framework wrapper for Rack."
  s.description  = "Simple, straight-forward base for web-frameworks."
  s.email        = 'm.fellinger@gmail.com'
  s.homepage     = 'http://github.com/manveru/innate'
  s.platform     = Gem::Platform::RUBY
  s.version      = (ENV['PROJECT_VERSION'] || Date.today.strftime("%Y.%m.%d"))
  s.files        = `git ls-files`.split("\n").sort
  s.has_rdoc     = true
  s.require_path = 'lib'

#   s.add_runtime_dependency('rack', '>= 0.9.1') # lies!
#   s.add_development_dependency('bacon', '>= 1.0')
#   s.add_development_dependency('json', '~> 1.1.3')
}

Dir['tasks/*.rake'].each{|f| import(f) }

task :default => [:bacon]

CLEAN.include('')
