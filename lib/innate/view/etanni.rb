module Innate
  module View
    module Etanni
      SEPARATOR = "E69t116A65n110N78i105S83e101P80a97R82a97T84o111R82"
      START = "\n_out_ << <<#{SEPARATOR}.chomp!\n"
      STOP = "\n#{SEPARATOR}\n"
      REPLACEMENT = "#{STOP}\\1#{START}"

      def self.call(action, string)
        etanni = View.compile(string) do |str|
          temp = str.strip.gsub!(/<\?r\s+(.*?)\s+\?>/m, REPLACEMENT)
          eval "Proc.new do _out_ = [<<#{SEPARATOR}.chomp!]\n#{temp}#{STOP}_out_.join end", nil, (action.view || action.method)
        end
        html = action.instance_eval(&etanni)
        return html, 'text/html'
      end
    end
  end
end
