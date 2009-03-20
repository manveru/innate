require 'innate/state/accessor'
require 'innate/request'

module Innate
  # The module to be included into the Controller it basically just provides
  # #request, #response and #session, each accessing Thread.current to
  # retrieve the demanded object

  module Trinity
    extend StateAccessor

    state_accessor :request, :response, :session, :actions

    def action
      actions.last
    end
  end
end
