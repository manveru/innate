require 'logger'
require 'pp'

require 'innate/log/hub'
require 'innate/log/color_formatter'

module Innate
  logger = Logger.new($stderr)

  begin
    require 'win32console' if RUBY_PLATFORM =~ /win32/i
    logger.formatter = ColorFormatter.new
  rescue LoadError => ex
    logger.error "For nice colors on windows, please `gem install win32console`"
    logger.error ex
  end

  Log = LogHub.new(logger)
  Log.debug 'Logger initialized'
end
