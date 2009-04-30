module Innate
  module View
    module Etanni
      def self.call(action, string)
        etanni = View.compile(string){|s| Innate::Etanni.new(s) }
        html = etanni.result(action.binding, (action.view || action.method))
        return html, 'text/html'
      end
    end
  end

  class Etanni
    def initialize(template)
      @template = template
      compile
    end

    def compile
      temp = @template.dup
      separator = "T" << Digest::SHA1.hexdigest(temp)
      from, to = "\n<<#{separator}.chomp\n", "\n#{separator}\n"
      bufadd = "_out_ << "

      temp.gsub!(/<\?r\s+(.*?)\s+\?>/m, "#{to} \\1; #{bufadd} #{from}")

      @compiled = "_out_ = ''; #{bufadd} #{from} #{temp} #{to}; _out_"
    end

    def result(binding, filename = '<Etanni>')
      eval(@compiled, binding, filename).to_s.strip
    end
  end
end
