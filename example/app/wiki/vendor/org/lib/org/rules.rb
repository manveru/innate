require 'org'

# rs = RuleSet.new("~/c/innate/example/app/wiki/pages/Home.owl")
rs = OrgMarkup.new("test.org")

rs.scope(:block, :indent => true) do |block|
  block.rule :header, /(\*+)\s+(.*)\n/, :bol => true
  block.rule :table, /\|([^|]+)/, :bol => true, :start => :table, :unscan => true
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
    # [[file:foo][My file foo]]
    parent.rule :a, /\[\[([^:\]]+):([^\]]+)\]\[([^\]]+)\]\]/
    # [[http://go.to/][Go to]]
    parent.rule :a, /\[\[([^\]]+)\]\[([^\]]+)\]\]/
    # [[file:foo]]
    parent.rule :a, /\[\[([^:\]]+):([^\]]+)\]\]/
    # [[foo]]
    parent.rule :a, /\[\[([^\]]+)\]\]/
    parent.rule :italic, /\/([^\/]+)\//
    parent.rule :bold, /\*([^*]+)\*/, :tag => :b
    parent.rule :underline, /_([^_]+)_/
    parent.rule :strikethrough, /\+([^+]+)\+/
    parent.rule :verbatim, /~([^~]+)~/
    parent.rule :code, /\=([^=]+)\=/
  end

  block.scope(:inline, :indent => false) do |inline|
    inline.apply(&inline_rules)
    inline.rule :text, /(.)/
    inline.rule :close, /\n\n+/, :end => :inline
    inline.rule :br, /\n/
  end

  block.scope(:table, :indent => true) do |table|
#     | name   | telelphone | room |
#     |--------+------------+------|
#     | Mr. X  |    777-777 |   42 |
#     | Mrs. Y |    888-888 |   21 |

    table.rule :tr, /\|([^|]+)/, :bol => true, :unscan => true, :start => :tr
    table.rule :close, /\n/, :end => :table

    table.scope(:tr, :indent => true) do |tr|
      tr.rule :table_separator, /\|[+-]+\|/
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

require 'pp'

class OrgMarkup
  module ToHtml
    def html_link(leader, href = nil, title = nil)
      case leader
      when 'rss'
        link_rss(href, title)
      when 'file'
        link_file(href, title)
      when 'http', 'https', 'ftp'
        link_out("#{leader}:#{href}", title)
      else
        link_in(leader, href)
      end
    end

    # Respond to [[rss:href]] and [[rss:href][title]]
    def link_rss(href, title)
      "<rss %p %p>" % [href, title]
      ''
    end

    # Respond to [[file:href]] and [[file:href][title]]
    def link_file(href, title)
      "<file %p %p>" % [href, title]
      ''
    end

    def link_out(href, title)
      "<out %p %p>" % [href, title]
      tag(:a, title || href, :href => href)
    end

    # Respond to [[name]] and [[name][title]]
    def link_in(href, title)
      "<wiki %p %p>" % [href, title]
      tag(:a, title || href, :href => "/#{href}")
    end
  end
end
