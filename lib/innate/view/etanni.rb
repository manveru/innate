module Innate
  module View
    module Etanni
      def self.call(action, string)
        template = Innate::Etanni.new(string.to_s)
        html = template.result(action.binding, (action.view || action.method))
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
      start_heredoc = "T" << Digest::SHA1.hexdigest(temp)
      start_heredoc, end_heredoc = "\n<<#{start_heredoc}.chomp\n", "\n#{start_heredoc}\n"
      bufadd = "_out_ << "

      temp.gsub!(/<\?r\s+(.*?)\s+\?>/m,
            "#{end_heredoc} \\1; #{bufadd} #{start_heredoc}")

      @compiled = "_out_ = ''
      #{bufadd} #{start_heredoc} #{temp} #{end_heredoc}
      _out_"
    end

    def result(binding, filename = '<Etanni>')
      eval(@compiled, binding, filename).to_s.strip
    end
  end
end
