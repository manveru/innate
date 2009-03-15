module Innate
  # this is just a stub so other modules can register their options in here,
  # the real options are set in lib/innate.rb

  class << self; attr_reader :options; end
  @options = Options.new('Innate')
end
