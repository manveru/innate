desc 'install dependencies from gemspec'
task :install_dependencies => [:gem_installer] do
  GemInstaller.new{ setup_gemspec(GEMSPEC) }
end
