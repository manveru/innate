# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{innate}
  s.version = "2009.03.28"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael 'manveru' Fellinger"]
  s.date = %q{2009-03-28}
  s.description = %q{Simple, straight-forward base for web-frameworks.}
  s.email = %q{m.fellinger@gmail.com}
  s.files = ["CHANGELOG", "COPYING", "MANIFEST", "README.md", "Rakefile", "example/app/retro_games.rb", "example/app/todo/layout/default.erb", "example/app/todo/spec/todo.rb", "example/app/todo/start.rb", "example/app/todo/view/index.erb", "example/app/whywiki_erb/layout/wiki.html.erb", "example/app/whywiki_erb/spec/wiki.rb", "example/app/whywiki_erb/start.rb", "example/app/whywiki_erb/view/edit.html.erb", "example/app/whywiki_erb/view/index.html.erb", "example/custom_middleware.rb", "example/hello.rb", "example/howto_spec.rb", "example/link.rb", "example/provides.rb", "example/session.rb", "innate.gemspec", "lib/innate.rb", "lib/innate/action.rb", "lib/innate/adapter.rb", "lib/innate/cache.rb", "lib/innate/cache/api.rb", "lib/innate/cache/drb.rb", "lib/innate/cache/file_based.rb", "lib/innate/cache/marshal.rb", "lib/innate/cache/memory.rb", "lib/innate/cache/yaml.rb", "lib/innate/core_compatibility/basic_object.rb", "lib/innate/core_compatibility/string.rb", "lib/innate/current.rb", "lib/innate/dynamap.rb", "lib/innate/helper.rb", "lib/innate/helper/aspect.rb", "lib/innate/helper/cgi.rb", "lib/innate/helper/flash.rb", "lib/innate/helper/link.rb", "lib/innate/helper/partial.rb", "lib/innate/helper/redirect.rb", "lib/innate/helper/send_file.rb", "lib/innate/log.rb", "lib/innate/log/color_formatter.rb", "lib/innate/log/hub.rb", "lib/innate/middleware_compiler.rb", "lib/innate/mock.rb", "lib/innate/node.rb", "lib/innate/options.rb", "lib/innate/options/dsl.rb", "lib/innate/options/stub.rb", "lib/innate/request.rb", "lib/innate/response.rb", "lib/innate/route.rb", "lib/innate/session.rb", "lib/innate/session/flash.rb", "lib/innate/spec.rb", "lib/innate/state.rb", "lib/innate/state/accessor.rb", "lib/innate/state/fiber.rb", "lib/innate/state/thread.rb", "lib/innate/traited.rb", "lib/innate/trinity.rb", "lib/innate/version.rb", "lib/innate/view.rb", "lib/innate/view/erb.rb", "lib/innate/view/etanni.rb", "lib/innate/view/none.rb", "spec/example/hello.rb", "spec/example/link.rb", "spec/example/session.rb", "spec/helper.rb", "spec/innate/action/layout.rb", "spec/innate/action/layout/file_layout.erb", "spec/innate/cache/common.rb", "spec/innate/cache/marshal.rb", "spec/innate/cache/memory.rb", "spec/innate/cache/yaml.rb", "spec/innate/dynamap.rb", "spec/innate/helper.rb", "spec/innate/helper/aspect.rb", "spec/innate/helper/cgi.rb", "spec/innate/helper/flash.rb", "spec/innate/helper/link.rb", "spec/innate/helper/partial.rb", "spec/innate/helper/redirect.rb", "spec/innate/helper/send_file.rb", "spec/innate/helper/view/aspect_hello.erb", "spec/innate/helper/view/locals.erb", "spec/innate/helper/view/loop.erb", "spec/innate/helper/view/num.erb", "spec/innate/helper/view/partial.erb", "spec/innate/helper/view/recursive.erb", "spec/innate/mock.rb", "spec/innate/node/mapping.rb", "spec/innate/node/node.rb", "spec/innate/node/resolve.rb", "spec/innate/node/view/another_layout/another_layout.erb", "spec/innate/node/view/bar.erb", "spec/innate/node/view/foo.html.erb", "spec/innate/node/view/only_view.erb", "spec/innate/node/view/with_layout.erb", "spec/innate/node/wrap_action_call.rb", "spec/innate/options.rb", "spec/innate/parameter.rb", "spec/innate/provides.rb", "spec/innate/provides/list.html.erb", "spec/innate/provides/list.txt.erb", "spec/innate/request.rb", "spec/innate/route.rb", "spec/innate/session.rb", "spec/innate/state/fiber.rb", "spec/innate/state/thread.rb", "spec/innate/traited.rb", "tasks/bacon.rake", "tasks/changelog.rake", "tasks/gem.rake", "tasks/gem_installer.rake", "tasks/grancher.rake", "tasks/install_dependencies.rake", "tasks/manifest.rake", "tasks/rcov.rake", "tasks/release.rake", "tasks/reversion.rake"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/manveru/innate}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Powerful web-framework wrapper for Rack.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 0.9.1"])
      s.add_development_dependency(%q<bacon>, [">= 1.0"])
      s.add_development_dependency(%q<json>, ["~> 1.1.3"])
    else
      s.add_dependency(%q<rack>, [">= 0.9.1"])
      s.add_dependency(%q<bacon>, [">= 1.0"])
      s.add_dependency(%q<json>, ["~> 1.1.3"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0.9.1"])
    s.add_dependency(%q<bacon>, [">= 1.0"])
    s.add_dependency(%q<json>, ["~> 1.1.3"])
  end
end
