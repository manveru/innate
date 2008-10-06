module Org
  class RootToken
    def to_toc
      found = @childs.map{|child| child.to_toc }.flatten.compact

      out = []
      nest = 0

      while token = found.shift
        level, text = *token.values
        level = level.size

        if level > nest
          out << '<ol>'
        elsif level < nest
          out << '</ol>'
        end
        nest = level

        out << "<li>#{token.toc_link}</li>"
      end

      nest.times do
        out << '</ol>'
      end

      out
    end
  end

  module ToToc
    TOC_ENTRIES = [:header]

    def to_toc
      case @name
      when *TOC_ENTRIES
        self
      else
        @childs.map{|child| child.to_toc }
      end
    end

    def toc_link
      tag(:a, values[1], :href => "##{toc_id}")
    end

    def toc_id
      values[1].gsub(/\W/, '-').squeeze('-').downcase
    end
  end
end
