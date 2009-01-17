require 'innate/log/hub'
require 'innate/log/color_formatter'

module Innate
  logdev, *params = options.log.params
  color = options.log.color
  color = Logger::ColorFormatter.color?(logdev) if color.nil?

  logger = Logger.new(logdev, *params)

  if color
    begin
      require 'win32console' if RUBY_PLATFORM =~ /win32/i

      logger.formatter = Logger::ColorFormatter.new

    rescue LoadError
      logger.debug "For colors on windows, please `gem install win32console`"
    end
  end

  Log = LogHub.new(logger)
end
