Options.for(:wiki){|wiki|
  wiki.title = 'Ramaze Wiki'
  wiki.root = File.dirname(__FILE__)
  wiki.repo = File.expand_path(ENV['WIKI_HOME'] || File.join(wiki.root, 'pages'))
}

OWLScribble.each_wiki_link do |tag, page_name, link_text|
  tag.name  = 'a'
  tag.href  = "/#{Rack::Utils.escape(page_name)}"
  tag.text  = link_text.dewikiword
  c = Page[page_name].exists? ? 'existing-wiki-link' : 'missing-wiki-link'
  tag.class = c
end

OWLScribble.each_wiki_command do |tag, command, params|
  case command
  when 'include'
    tag.name = 'div'
    tag.class = 'included'
    tag.text = Page.get(*params).render
  else
    tag.name  = 'span'
    tag.class = 'unhandled_command'
    tag.text = "###{command}( #{params.join ', '} )##"
  end
end
