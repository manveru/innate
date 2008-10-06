Options.for(:wiki){|wiki|
  wiki.title = 'Ramaze Wiki'
  wiki.root = File.dirname(__FILE__)
  wiki.repo = File.expand_path(ENV['WIKI_HOME'] || File.join(wiki.root, 'pages'))
}

require 'org/scope/org_mode'
require 'org/to/html'
require 'org/to/toc'

module Org
  class Token
    include ToHtml
    include ToToc

    def html_a
      link, desc = *values

      if link =~ /:/
        leader, rest = link.split(/:/, 2)

        case leader
        when /^(https?|ftps?)$/
          link_external(link, desc || link)
        when /^swf$/
          link_swf(rest, desc)
        when /^irc$/
          link_irc(rest, desc)
        when /^wp$/
          link_wikipedia(rest, desc)
        else
          link_external(link, desc || link)
        end
      else
        link_internal(link, desc || link)
      end
    end

    LINKS = {} unless defined?(LINKS)

    def link_internal(link, desc)
      this = Innate::Current::action.params.join('/')
      add_node(this, link)
      exists = Page[link.split('#').first].exists?
      style = "#{exists ? 'existing' : 'missing'}-wiki-link"
      tag(:a, desc, :href => PageNode.r(link), :class => style)
    end

    def add_node(this, link)
      this = 'Home' if this.empty?
      LINKS[this] ||= Set.new
      LINKS[this] << link
    end

    def link_external(link, desc)
      tag(:a, desc, :href => link, :class => 'wiki-link-external')
    end

    def link_irc(link, desc)
      tag(:a, desc, :href => "irc://#{link}", :class => 'wiki-link-external')
    end

    def link_wikipedia(link, desc)
      tag(:a, desc, :href => "http://en.wikipedia.org/w/#{link}", :class => 'wiki-link-external')
    end

    # what a fantastically cheap hack :)
    # use in your wiki like:
    # [[swf:some-vid][width: 600; height: 700; play: true]]
    SWF_DEFAULT = '; loop: false; quality: low; play: false'

    def link_swf(file, args)
      args << SWF_DEFAULT << "; movie: /swf/#{file}.swf"
      template = SWF_TEMPLATE.dup
      args.split(/\s*;\s*/).each do |subarg|
        key, value = subarg.split(/\s*:\s*/)
        template.gsub!("{#{key}}", value)
      end

      return template
    end

    SWF_TEMPLATE = <<'SWF_TEMPLATE'
<center>
  <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="{width}" height="{height}" codebase="http://active.macromedia.com/flash5/cabs/swflash.cab#version=5,0,0,0">
    <param name=movie value="{movie}">
    <param name=play value={play}>
    <param name=loop value={loop}>
    <param name=quality value={quality}>
    <embed src="{movie}" width={width} height={height} quality={quality} loop={loop} type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash">
  </embed>
  </object>
</center>
</html>
SWF_TEMPLATE
  end
end
