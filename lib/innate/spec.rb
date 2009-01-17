require File.expand_path(File.join(File.dirname(__FILE__), '../innate'))

require 'bacon'

Bacon.summary_on_exit
Bacon.extend(Bacon::TestUnitOutput)

Innate.middleware :innate do |m|
  m.use Innate::Current
  m.cascade(
    Innate::Rewrite.new(Innate::DynaMap),
    Innate::Route.new(Innate::DynaMap)
  )
end

Innate.options.started = true
