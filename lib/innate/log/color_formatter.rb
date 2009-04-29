class Logger
  # Extended Formatter that supports ANSI colors.
  #
  # The basic mapping of ANSI colors is as follows:
  #
  #     | reset | bold | dark | underline | blink | negative
  # MOD |     0 |    1 |    2 |         4 |     5 |        7
  #
  #    | black | red | green | yellow | blue | magenta | cyan | white
  # FG |    30 |  31 |    32 |     33 |   34 |      35 |   36 |    37
  # BG |    40 |  41 |    42 |     43 |   44 |      45 |   46 |    47
  #
  # The output is done by: "\e[#{mod};#{fg};#{bg}m#{string}\e[0m"
  # The suffix is to reset the terminal to the original state again.
  class ColorFormatter < Formatter
    LEVEL_COLOR = {
      'DEBUG'   => "\e[0;34;40m%s\e[0m", # blue on black
      'INFO'    => "\e[0;37;40m%s\e[0m", # white on black
      'WARN'    => "\e[0;33;40m%s\e[0m", # yellow on black
      'ERROR'   => "\e[0;31;40m%s\e[0m", # red on black
      'FATAL'   => "\e[0;35;40m%s\e[0m", # red on black
      'UNKNOWN' => "\e[0;32;40m%s\e[0m", # green on black
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
      LEVEL_COLOR[severity] % string
    end

    def self.color?(logdev)
      logdev.respond_to?(:tty?) and logdev.tty?
    end
  end
end
