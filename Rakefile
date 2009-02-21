require 'rake/rdoctask'
require 'rake/clean'
require 'time'
require 'date'
require 'pp'

INNATE_VERSION = Date.today.strftime("%Y.%m.%d")

task :default => [:spec]
task :publish => [:ydoc]

CLEAN.include('*coverage*')

desc 'update lib/innate/version.rb'
task :reversion do
  File.open('lib/innate/version.rb', 'w+') do |file|
    file.puts('module Innate')
    file.puts('  VERSION = %p' % INNATE_VERSION)
    file.puts('end')
  end
end

desc 'publish to github'
task :release => [:reversion, :gemspec] do
  sh('git add MANIFEST CHANGELOG innate.gemspec lib/innate/version.rb')
  puts "I added the relevant files, you can now run:", ''
  puts "git commit -m 'Version #{INNATE_VERSION}'"
  puts "git tag -a -m '#{INNATE_VERSION}' '#{INNATE_VERSION}'"
  puts "git push"
  puts
end

desc 'update manifest'
task :manifest do
  File.open('MANIFEST', 'w+') do|manifest|
    manifest.puts(`git ls-files`)
  end
end

desc 'update changelog'
task :changelog do
  File.open('CHANGELOG', 'w+') do |changelog|
    `git log -z --abbrev-commit`.split("\0").each do |commit|
      next if commit =~ /^Merge: \d*/
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

desc 'generate gemspec'
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

  # we ignore adapter as this has extensive specs in rack already.
  ignore = %w[ gem rack bacon innate/adapter\.rb ]
  ignore << 'fiber\.rb' if RUBY_VERSION < '1.9'

  ignored = ignore.join(',')

  cmd = "rcov --aggregate coverage.data --sort coverage -t --%s -x '#{ignored}' %s"

  while spec = specs.shift
    puts '', "Gather coverage for #{spec} ..."
    html = specs.empty? ? 'html' : 'no-html'
    sh(cmd % [html, spec])
  end
end

desc 'Run all specs'
task :spec => :setup do
  require 'open3'
  require 'scanf'

  specs = Dir['spec/{innate,example}/**/*.rb']
  specs.delete_if{|f| f =~ /cache\/common\.rb/ }

  some_failed = false
  total = specs.size
  len = specs.map{|s| s.size }.sort.last
  tt = ta = tf = te = 0

  red, green = "\e[31m%s\e[0m", "\e[32m%s\e[0m"
  left_format = "%4d/%d: %-#{len + 11}s"
  spec_format = "%d specifications (%d requirements), %d failures, %d errors"

  specs.each_with_index do |spec, idx|
    print(left_format % [idx + 1, total, spec])

    Open3.popen3("#{RUBY} #{spec}") do |sin, sout, serr|
      out = sout.read
      err = serr.read

      out.each_line do |line|
        tests, assertions, failures, errors = all = line.scanf(spec_format)
        next unless all.any?
        tt += tests; ta += assertions; tf += failures; te += errors

        if tests == 0 || failures + errors > 0
          puts((red % spec_format) % all)
          puts out
          puts err
        else
          puts((green % "%6d passed") % tests)
        end

        break
      end
    end
  end

  puts(spec_format % [tt, ta, tf, te])
  exit 1 if some_failed
end

desc 'Generate YARD documentation'
task :ydoc do
  sh('yardoc -o ydoc -r README.md')
end

begin
  require 'grancher/task'

  Grancher::Task.new do |g|
    g.branch = 'gh-pages'
    g.push_to = 'origin'
    g.message = 'Updated website'
    g.directory 'ydoc', 'doc'
  end
rescue LoadError
  # oh well :)
end

desc 'install dependencies'
task :setup do
  GemSetup.new do
    github = 'http://gems.github.com'
    Gem.sources << github

    gem('rack', '>=0.9.1')
    gem('bacon', '>=1.1.0')

    setup
  end
end

class GemSetup
  def initialize(options = {}, &block)
    @gems = []
    @options = options

    run(&block)
  end

  def run(&block)
    instance_eval(&block) if block_given?
  end

  def gem(name, version = nil, options = {})
    if version.respond_to?(:merge!)
      options = version
    else
      options[:version] = version
    end

    @gems << [name, options]
  end

  def setup
    require 'rubygems'
    require 'rubygems/dependency_installer'

    @gems.each do |name, options|
      setup_gem(name, options)
    end
  end

  def setup_gem(name, options, try_install = true)
    print "activating #{name} ... "
    Gem.activate(name, *[options[:version]].compact)
    require(options[:lib] || name)
    puts "success."
  rescue LoadError => error
    puts error
    install_gem(name, options) if try_install
    setup_gem(name, options, try_install = false)
  end

  def install_gem(name, options)
    installer = Gem::DependencyInstaller.new(options)

    temp_argv(options[:extconf]) do
      print "Installing #{name} ... "
      installer.install(name, options[:version])
      puts "done."
    end
  end

  def temp_argv(extconf)
    if extconf ||= @options[:extconf]
      old_argv = ARGV.clone
      ARGV.replace(extconf.split(' '))
    end

    yield

  ensure
    ARGV.replace(old_argv) if extconf
  end
end
