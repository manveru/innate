class Logger
  # Extended Formatter that supports ANSI colors.
  class ColorFormatter < Formatter
    LEVEL_COLOR = {
      'DEBUG'   => :blue,
      'INFO'    => :white,
      'WARN'    => :yellow,
      'ERROR'   => :red,
      'FATAL'   => :red,
      'UNKNOWN' => :green,
    }

    COLOR_CODE = {
      :reset => 0, :bold => 1, :dark => 2, :underline => 4, :blink => 5,
      :negative => 7, :black => 30, :red => 31, :green => 32, :yellow => 33,
      :blue => 34, :magenta => 35, :cyan => 36, :white => 37,
    }

    FORMAT_TIME = "%Y-%m-%d %H:%M:%S"
    FORMAT_LINE = "%s [%s $%d] %5s | %s: %s\n"

    def call(severity, time, program, message)
      hint = severity[0,1]
      time = format_time(time)
      pid = $$
      string = colorize(msg2str(message), severity)

      FORMAT_LINE % [hint, time, pid, severity, program, string]
    end

    def format_time(time)
      time.strftime(FORMAT_TIME)
    end

    def colorize(string, severity)
      "\e[#{COLOR_CODE[LEVEL_COLOR[severity]]}m#{string}\e[0m"
    end

    def self.color?(logdev)
      logdev.respond_to?(:tty?) and logdev.tty?
    end
  end
end
