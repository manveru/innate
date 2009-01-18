require File.expand_path(File.join(File.dirname(__FILE__), '../innate'))

require 'bacon'

Bacon.summary_on_exit
Bacon.extend(Bacon::TestUnitOutput)

module Innate
  # minimal middleware, no exception handling
  middleware(:innate){|m| m.innate }

  # skip merging of options
  options.started = true
end
