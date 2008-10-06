module Org
  class State < Struct.new(:scope, :parent, :scanner)
    def step
      loop do
        # before = scanner.string[0...scanner.pos][-25, 25]
        # after = scanner.string[scanner.pos..-1][0, 50]
        # p "%40s@%40s" % [before, after]
        break unless scope.step(self)
      end
    end
  end
end
