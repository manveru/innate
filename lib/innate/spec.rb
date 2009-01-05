begin; require 'rubygems'; rescue LoadError; end

require 'bacon'

Bacon.summary_on_exit
Bacon.extend(Bacon::TestUnitOutput)

require File.expand_path(File.join(File.dirname(__FILE__), '../innate'))

Innate.middleware :innate do |m|
  m.use Innate::Current
  m.cascade Innate::DynaMap
end

Innate.options.started = true
