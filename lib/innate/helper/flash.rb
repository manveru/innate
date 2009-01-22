module Innate
  module Helper
    # Simple access to session.flash.
    #
    # Flash is a mechanism using sessions to provide a rotating holder of
    # key/value pairs.
    #
    # Every request that is made will rotate one step, dropping contents stored
    # two requests ago.
    #
    # The purpose of this class is to provide an easy way of setting/retrieving
    # from the current flash.
    #
    # Flash is a way to keep a temporary pairs of keys and values for the duration
    # of two requests, the current and following.
    #
    # Very vague Example:
    #
    # On the first request, for example on registering:
    #
    #   flash[:error] = "You should reconsider your username, it's taken already"
    #   redirect R(self, :register)
    #
    # This is the request from the redirect:
    #
    #   do_stuff if flash[:error]
    #
    # On the request after this, flash[:error] is gone.
    module Flash
      # Just for convenience
      def flash
        session.flash
      end
    end
  end
end
