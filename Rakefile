require 'rake/rdoctask'
require 'rake/clean'
require 'time'
require 'date'
require 'pp'

INNATE_VERSION = Date.today.strftime("%Y.%m.%d")

task :default => [:spec]

CLEAN.include('*coverage*')

desc "Run all specs"
task :spec do
  exclude = [/cache\/common\.rb/]

  Dir['spec/innate/**/*.rb'].each do |rb|
    case rb
    when *exclude
    else
      puts "", rb
      ruby rb
    end
  end
end

task :reversion do
  File.open('lib/innate/version.rb', 'w+') do |file|
    file.puts('module Innate')
    file.puts('  VERSION = %p' % INNATE_VERSION)
    file.puts('end')
  end
end

task :release => [:reversion, :gemspec] do
  sh('git add MANIFEST CHANGELOG innate.gemspec lib/innate/version.rb')
  puts "I added the relevant files, you can now run:", ''
  puts "git commit -m 'Version #{INNATE_VERSION}'"
  puts "git tag -d '#{INNATE_VERSION}'"
  puts "git push"
  puts
end

task :manifest do
  File.open('MANIFEST', 'w+') do|manifest|
    manifest.puts(`git ls-files`)
  end
end

task :changelog do
  File.open('CHANGELOG', 'w+') do |changelog|
    `git log -z --abbrev-commit`.split("\0").each do |commit|
      ref, author, time, _, title, _, message = commit.split("\n", 7)
      ref    = ref[/commit ([0-9a-f]+)/, 1]
      author = author[/Author: (.*)/, 1].strip
      time   = Time.parse(time[/Date: (.*)/, 1]).utc
      title.strip!

      changelog.puts "[#{ref} | #{time}] #{author}"
      changelog.puts '', "  * #{title}"
      changelog.puts '', message.rstrip if message
      changelog.puts
    end
  end
end

task :gemspec => [:manifest, :changelog] do
  manifest = File.read('MANIFEST').split("\n")
  files = manifest.map{|file| "    %p," % file }.join("\n")[0..-2]

gemspec = <<-GEMSPEC
Gem::Specification.new do |s|
  s.name = "innate"
  s.version = #{INNATE_VERSION.dump}

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
#{files}
  ]
end
GEMSPEC

  File.open('innate.gemspec', 'w+'){|gs| gs.puts(gemspec) }
end

desc 'code coverage'
task :rcov => :clean do
  specs = Dir['spec/innate/**/*.rb']
  specs -= Dir['spec/innate/cache/common.rb']

  ignore = %w[ gem rack bacon ]
  ignore << 'fiber\.rb' if RUBY_VERSION < '1.9'

  ignored = ignore.join(',')

  cmd = "rcov --aggregate coverage.data --sort coverage -t --%s -x '#{ignored}' %s"

  while spec = specs.shift
    puts '', "Gather coverage for #{spec} ..."
    html = specs.empty? ? 'html' : 'no-html'
    sh(cmd % [html, spec])
  end
end
