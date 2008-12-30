require 'bacon'

Bacon.summary_on_exit
Bacon.extend(Bacon::TestUnitOutput)

require 'innate'

Innate.middleware :innate do |m|
  m.use Rack::Lint
  m.use Innate::Current
  m.cascade Innate::DynaMap
end

Innate.options.started = true
