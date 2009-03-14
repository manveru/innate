require 'innate/log/hub'
require 'innate/log/color_formatter'

module Innate
  logdev = $stderr
  logger = Logger.new(logdev)

  if Logger::ColorFormatter.color?(logdev)
    begin
      require 'win32console' if RUBY_PLATFORM =~ /win32/i

      logger.formatter = Logger::ColorFormatter.new

    rescue LoadError
      logger.debug "For colors on windows, please `gem install win32console`"
    end
  end

  Log = LogHub.new(logger)
end
