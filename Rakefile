require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'time'
require 'date'

PROJECT_SPECS = FileList['spec/{innate,example}/**/*.rb'].exclude('common.rb')
PROJECT_MODULE = 'Innate'
PROJECT_README = 'README.md'
PROJECT_VERSION = ENV['VERSION'] || Date.today.strftime('%Y.%m.%d')

DEPENDENCIES = {
  'rack' => {:version => '~> 1.0.0'},
}

DEVELOPMENT_DEPENDENCIES = {
  'bacon'     => {:version => '>= 1.1.0'},
  'json'      => {:version => '~> 1.1.7'},
  'rack-test' => {:version => '>= 0.4.0', :lib => 'rack/test'}
}

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
  s.required_rubygems_version = '>= 1.3.1'
}

DEPENDENCIES.each do |name, options|
  GEMSPEC.add_dependency(name, options[:version])
end

DEVELOPMENT_DEPENDENCIES.each do |name, options|
  GEMSPEC.add_development_dependency(name, options[:version])
end

Dir['tasks/*.rake'].each{|f| import(f) }

task :default => [:bacon]

CLEAN.include('')
