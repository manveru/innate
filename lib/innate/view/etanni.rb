module Innate
  module View
    module Etanni
      def self.call(action, string)
        filename = action.view || action.method
        etanni = View.compile(string){|str| Innate::Etanni.new(str, filename) }
        html = etanni.result(action.binding)
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
      @compiled = eval("lambda{ _out_ = [#{CHOMP}]\n#{temp}#{STOP}_out_.join }",
        nil, @filename)
    end

    def result(binding, filename = @filename)
      eval('self', binding).instance_eval(&@compiled)
    end
  end
end
