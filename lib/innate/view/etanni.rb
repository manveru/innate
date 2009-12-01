module Innate
  module View
    module Etanni
      def self.call(action, string)
        etanni = View.compile(string){|str| Innate::Etanni.new(str) }
        html = etanni.result(action.binding, (action.view || action.method))
        return html, 'text/html'
      end
    end
  end

  class Etanni
    SEPARATOR = "E69t116A65n110N78i105S83e101P80a97R82a97T84o111R82"
    START = "\n_out_ << <<#{SEPARATOR}.chomp!\n"
    STOP = "\n#{SEPARATOR}\n"
    REPLACEMENT = "#{STOP}\\1#{START}"

    def initialize(template)
      @template = template
      compile
    end

    def compile
      temp = @template.dup
      temp.strip!
      temp.gsub!(/<\?r\s+(.*?)\s+\?>/m, REPLACEMENT)
      @compiled = "_out_ = [<<#{SEPARATOR}.chomp!]\n#{temp}#{STOP}_out_"
    end

    def result(binding, filename = '<Etanni>')
      eval(@compiled, binding, filename).join
    end
 end
end
