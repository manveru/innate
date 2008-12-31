Gem::Specification.new do |s|
  s.name = "innate"
  s.version = "2008.12.31"

  s.summary = "Powerful web-framework wrapper for Rack."
  s.description = "Simple, straight-forward, base for web-frameworks."
  s.platform = "ruby"
  s.has_rdoc = true
  s.author = "Michael 'manveru' Fellinger"
  s.email = "m.fellinger@gmail.com"
  s.homepage = "http://github.com/manveru/innate"
  s.require_path = "lib"

  s.add_dependency('rack', '>= 0.4.0')

  s.files = [
    "CHANGELOG",
    "COPYING",
    "MANIFEST",
    "README.md",
    "Rakefile",
    "example/app/retro_games.rb",
    "example/app/whywiki_haml/layout/wiki.haml",
    "example/app/whywiki_haml/spec/wiki.rb",
    "example/app/whywiki_haml/start.rb",
    "example/app/whywiki_haml/view/edit.haml",
    "example/app/whywiki_haml/view/index.haml",
    "example/app/whywiki_nagoro/layout/wiki.xhtml",
    "example/app/whywiki_nagoro/spec/wiki.rb",
    "example/app/whywiki_nagoro/start.rb",
    "example/app/whywiki_nagoro/view/edit.haml",
    "example/app/whywiki_nagoro/view/edit.xhtml",
    "example/app/whywiki_nagoro/view/index.xhtml",
    "example/app/whywiki_nagoro/wiki.yaml",
    "example/custom_middleware.rb",
    "example/hello.rb",
    "example/howto_spec.rb",
    "example/link.rb",
    "example/providing_hash.rb",
    "example/session.rb",
    "innate.gemspec",
    "lib/innate.rb",
    "lib/innate/action.rb",
    "lib/innate/adapter.rb",
    "lib/innate/adapter/fake.rb",
    "lib/innate/adapter/thin.rb",
    "lib/innate/cache.rb",
    "lib/innate/cache/api.rb",
    "lib/innate/cache/memory.rb",
    "lib/innate/cache/yaml.rb",
    "lib/innate/core_compatibility/basic_object.rb",
    "lib/innate/core_compatibility/string.rb",
    "lib/innate/current.rb",
    "lib/innate/dynamap.rb",
    "lib/innate/helper.rb",
    "lib/innate/helper/aspect.rb",
    "lib/innate/helper/cgi.rb",
    "lib/innate/helper/link.rb",
    "lib/innate/helper/redirect.rb",
    "lib/innate/log.rb",
    "lib/innate/log/color_formatter.rb",
    "lib/innate/log/hub.rb",
    "lib/innate/mock.rb",
    "lib/innate/node.rb",
    "lib/innate/option.rb",
    "lib/innate/request.rb",
    "lib/innate/session.rb",
    "lib/innate/setup.rb",
    "lib/innate/spec.rb",
    "lib/innate/state.rb",
    "lib/innate/state/accessor.rb",
    "lib/innate/state/fiber.rb",
    "lib/innate/state/thread.rb",
    "lib/innate/trinity.rb",
    "lib/innate/view.rb",
    "lib/innate/view/builder.rb",
    "lib/innate/view/haml.rb",
    "lib/innate/view/nagoro.rb",
    "lib/innate/view/none.rb",
    "lib/innate/view/sass.rb",
    "lib/innate/view/tenjin.rb",
    "lib/rack/middleware_compiler.rb",
    "lib/rack/profile.rb",
    "lib/rack/reloader.rb",
    "spec/helper.rb",
    "spec/innate/cache/memory.rb",
    "spec/innate/cache/yaml.rb",
    "spec/innate/helper.rb",
    "spec/innate/mock.rb",
    "spec/innate/node.rb",
    "spec/innate/node/bar.css",
    "spec/innate/node/foo.css.sass",
    "spec/innate/options.rb",
    "spec/innate/session.rb"
  ]
end
