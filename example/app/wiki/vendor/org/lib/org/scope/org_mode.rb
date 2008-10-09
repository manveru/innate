module Org
  OrgMode = Markup.new

  OrgMode.scope(:block, :indent => true) do |block|
    block.rule :header, /(\*+)\s+(.*)(\n|\z)/, :bol => true
    block.rule :table, /\|([^|]+)/, :bol => true, :start => :table, :unscan => true
    block.rule :ul, /[ \t]+(\*+)\s*(.*)/, :start => :ul, :unscan => true, :bol => true
    block.rule :br, /\n/
    block.rule :p, /(.)/, :bol => true, :start => :inline, :unscan => true
    block.rule :space, /\s/

    inline_rules = lambda do |parent|
      # * You can make words *bold*, /italic/, _underlined_, `=code=' and
      #   `~verbatim~', and, if you must, `+strikethrough+'.  Text in the
      #   code and verbatim string is not processed for org-mode specific
      #   syntax, it is exported verbatim.
      parent.rule :a, /\b([A-Z]\w+[A-Z]\w+)/
      parent.rule :text, /([A-Za-z0-9,. ]+)/
      #      parent.rule :text, /(\/\/)/
      parent.rule :a, /\[\[([^\]]+)\]\[([^\]]+)\]\]/
      parent.rule :a, /\[\[(.+?)\]\]/
      parent.rule :italic, /\/([^\/ ]+)\//, :tag => :i
      parent.rule :bold, /\*([^* ]+)\*/, :tag => :b
      parent.rule :underline, /_([^_ ]+)_/, :tag => :u
      parent.rule :strikethrough, /\+([^+ ]+)\+/, :tag => :s
      parent.rule :blockquote, /~([^~ ]+)~/
      parent.rule :code, /\=([^= ]+)\=/
      parent.rule :code, /`([^`]+)`/
      parent.rule :hr, /---+/, :bol => true
    end

    block.scope :ul do |ul|
      ul.rule :li, /[ \t]+\*+\s*/, :start => :li, :bol => true
      ul.rule :close, /\n/, :end => :ul
      ul.rule :close, /(.)/, :end => :ul, :unscan => true

      ul.scope :li do |li|
        li.apply(&inline_rules)
        li.rule :text, /(.)/
        li.rule :ul, /[ \t]+\*+\s*/, :start => ul, :bol => true
        li.rule :close, /\n/, :end => :li
      end
    end

    block.scope(:inline, :indent => false) do |inline|
      inline.apply(&inline_rules)
      inline.rule :highlight, /\{\{\{[\t ]*(\S+)\n(.*?)\n\}\}\}/m
      inline.rule :highlight, /\{\{\{\n(.*?)\n\}\}\}/m
      inline.rule :text, /(.)/
      inline.rule :close, /\n\n+/, :end => :inline
      inline.rule :br, /\n/
    end

    block.scope(:table, :indent => true) do |table|
      # | name   | telelphone | room |
      # |--------+------------+------|
      # | Mr. X  |    777-777 |   42 |
      # | Mrs. Y |    888-888 |   21 |

      table.rule :tr, /\|([^|]+)/, :bol => true, :unscan => true, :start => :tr
      table.rule :close, /\n/, :end => :table

      table.scope(:tr, :indent => true) do |tr|
        tr.rule :table_separator, /\|[+-]+\|/, :ignore => true
        tr.rule :close, /\|\n/, :end => :tr
        tr.rule :close, /\n/, :end => :tr
        tr.rule :td, /\|/, :start => :td

        tr.scope :td do |td|
          td.apply(&inline_rules)
          td.rule :space, /([\t ]+)/
          td.rule :text, /([^|])/
          td.rule :close, /\|/, :end => :td, :unscan => true
        end
      end
    end
  end
end
