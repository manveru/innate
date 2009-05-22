module Innate
  # Innate only provides logging via stdlib Logger to avoid bloat and
  # dependencies, you may specify multiple loggers in the Log instance of LogHub
  # to accomendate your needs, by default we log to $stderr to be compatible with
  # CGI.
  #
  # Please read the documentation of logger.rb (or even better, its source) to
  # get a feeling of how to use it correctly within Innate
  #
  # A few shortcuts:
  #
  # 1. Create logger for stderr/stdout
  #     logger = Logger.new($stdout)
  #     logger = Logger.new($stderr)
  #
  # 2. Create logger for a file
  #
  #     logger = Logger.new('test.log')
  #
  # 3. Create logger for file object
  #
  #     file = File.open('test.log', 'a+')
  #     logger = Logger.new(file)
  #
  # 4. Create logger with rotation on specified file size
  #
  #     # 10 files history, 5 MB each
  #     logger = Logger.new('test.log', 10, (5 << 20))
  #
  #     # 100 files history, 1 MB each
  #     logger = Logger.new('test.log', 100, (1 << 20))
  #
  # 5. Create a logger which ages logfiles daily/weekly/monthly
  #
  #     logger = Logger.new('test.log', 'daily')
  #     logger = Logger.new('test.log', 'weekly')
  #     logger = Logger.new('test.log', 'monthly')

  class LogHub
    include Logger::Severity
    include Optioned

    attr_accessor :loggers, :program, :active

    # +loggers+ should be a list of Logger instances
    def initialize(*loggers)
      @loggers = loggers.flatten
      @program = nil
      @active = true
      self.level = DEBUG
    end

    # set level for all loggers
    def level=(lvl)
      @loggers.each{|l| l.level = lvl }
      @level = lvl
    end

    def start; @active = true;  end
    def stop;  @active = false; end

    def method_missing(meth, *args, &block)
      eval %~
        def #{meth}(*args, &block)
          return unless @active
          args.each{|arg| @loggers.each{|logger| logger.#{meth}(arg, &block) }}
        end
      ~

      send(meth, *args, &block)
    end

    def write(*args)
      self.<<(*args)
    end
  end
end
