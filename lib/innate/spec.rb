require 'bacon'

Bacon.summary_on_exit
Bacon.extend(Bacon::TestUnitOutput)

require 'innate'

Innate.setup_middleware
Innate.config.started = true
