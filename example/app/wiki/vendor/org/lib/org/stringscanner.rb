require 'strscan'

module Org
  # Adding some comfort
  class StringScanner < ::StringScanner
    # Equivalent to Regexp#captures, returns Array of all matches
    def captures
      n = 0
      found = []
      while n += 1
        return found unless element = self[n]
        found << element
      end
    end
  end
end
