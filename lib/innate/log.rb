require 'innate/log/hub'
require 'innate/log/color_formatter'

module Innate
  logger = Logger.new($stderr)

  begin
    require 'win32console' if RUBY_PLATFORM =~ /win32/i
    logger.formatter = Logger::ColorFormatter.new
  rescue LoadError => ex
    logger.debug "For nice colors on windows, please `gem install win32console`"
  end

  Log = LogHub.new(logger)
end
