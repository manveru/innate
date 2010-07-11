module Innate
  module View
    module Etanni
      def self.call(action, string)
        etanni = View.compile(string) do |str|
          filename = action.view || action.method
          Innate::Etanni.new(str, filename)
        end
        html = etanni.result(action.instance)
        return html, Response.mime_type
      end
    end
  end

  class Etanni
    SEPARATOR = "E69t116A65n110N78i105S83e101P80a97R82a97T84o111R82"
    CHOMP = "<<#{SEPARATOR}.chomp!"
    START = "\n_out_ << #{CHOMP}\n"
    STOP = "\n#{SEPARATOR}\n"
    REPLACEMENT = "#{STOP}\\1#{START}"

    def initialize(template, filename = '<Etanni>')
      @template = template
      @filename = filename
      compile
    end

    def compile(filename = @filename)
      temp = @template.strip
      temp.gsub!(/<\?r\s+(.*?)\s+\?>/m, REPLACEMENT)
      @compiled = eval("Proc.new{ _out_ = [#{CHOMP}]\n#{temp}#{STOP}_out_.join }",
        nil, @filename)
    end

    def result(instance, filename = @filename)
      instance.instance_eval(&@compiled)
    end
  end
end
