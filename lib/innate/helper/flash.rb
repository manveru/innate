module Innate
  module Helper
    # Simple access to flash.
    #
    # Flash is a mechanism using sessions to provide a rotating holder of
    # key/value pairs.
    #
    # Every request that is made will rotate one step, dropping contents stored
    # two requests ago.
    module Flash
      # Just for convenience
      def flash
        session.flash
      end
    end
  end
end
