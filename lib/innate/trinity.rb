require 'innate/state/accessor'

module Innate
  # The module to be included into the Controller it basically just provides
  # #request, #response and #session, each accessing Thread.current to
  # retrieve the demanded object

  module Trinity
    extend StateAccessor

    state_accessor :request, :response, :session
  end
end
