require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'time'
require 'date'

PROJECT_SPECS = FileList['spec/{innate,example}/**/*.rb'].exclude('common.rb')
PROJECT_MODULE = 'Innate'
PROJECT_README = 'README.md'
PROJECT_VERSION = ENV['VERSION'] || Date.today.strftime('%Y.%m.%d')

GEMSPEC = Gem::Specification.new{|s|
  s.name         = 'innate'
  s.author       = "Michael 'manveru' Fellinger"
  s.summary      = "Powerful web-framework wrapper for Rack."
  s.description  = "Simple, straight-forward base for web-frameworks."
  s.email        = 'm.fellinger@gmail.com'
  s.homepage     = 'http://github.com/manveru/innate'
  s.platform     = Gem::Platform::RUBY
  s.version      = PROJECT_VERSION
  s.files        = `git ls-files`.split("\n").sort
  s.has_rdoc     = true
  s.require_path = 'lib'
  s.rubyforge_project = "innate"

  s.add_dependency('rack', '~> 1.0.0')

  # rip those out if they cause you trouble
  # s.add_development_dependency('bacon', '>= 1.0')
  # s.add_development_dependency('json', '~> 1.1.3')
  # s.add_development_dependency('rack-test', '>= 0.1.0')
}

Dir['tasks/*.rake'].each{|f| import(f) }

task :default => [:bacon]

CLEAN.include('')
