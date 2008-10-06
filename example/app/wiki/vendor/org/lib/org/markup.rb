module Org
  class Markup
    attr_accessor :string

    def initialize(file = nil)
      @string = File.read(file) if file
    end

    def apply(string = @string)
      parent = RootToken.new(:root, nil)
      scanner = StringScanner.new(string)
      state = State.new(@scope, parent, scanner)

      until scanner.eos?
        pos = scanner.pos
        # puts "=" * 80
        state.step
        # puts "=" * 80
        # pp state
        raise("Didn't move: %p" % scanner) if pos == scanner.pos
      end

      return parent
    end

    def scope(name, options = {}, &block)
      @scope = Scope.new(name, options)
      yield(@scope)
    end
  end
end
