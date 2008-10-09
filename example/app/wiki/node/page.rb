class PageNode
  include Innate::Node
  map '/'
  layout 'default'

  provide :html => :haml

  def index(*name)
    redirect r(:/, 'Home') if name.empty?
    @name = name.join('/')
    @page = Page[@name]
    @title = to_title(@name)
    @toc, @html = @page.to_toc, @page.to_html
  end

  def edit(*name)
    redirect_referrer if name.empty?
    @name = name.join('/')
    @page = Page[@name]
    @title = to_title(@name)
    @text = @page.content
  end

  def save
    name, text = request[:name, :text]
    page = Page[name]

    if text
      comment = page.exists? ? "Edit #{name}" : "Create #{name}"
      page.save(text, comment)
    end

    redirect r(:/, name)
  end

  def move
    from, to = request[:from, :to]

    if from and to
      Page[from].move(to)
      redirect r(to)
    end

    redirect r(from)
  end

  def delete(name)
    raise "change"
    Page[name].delete

    redirect r(:/)
  end

  def history(*name)
    @name = name.join('/')
    @page = Page[@name]
    @history = @page.history
  end

  def diff(sha, *file)
    @sha, @name = sha, file.join('/')
    style = session[:uv_style] = request[:uv_style] || session[:uv_style] || 'active_4d'
    @styles = Uv.themes
    @text = Page.new(@name).diff(sha, style)
  end

  def show(sha, *file)
    @sha, @name = sha, file.join('/')
    @page = Page.new(@name, sha)
    @title = to_title(@name)
    @toc, @html = @page.to_toc, @page.to_html
  end

  def list
    @list = nested_list(Page.list(locale))
  end

  def random
    redirect(r(:/, Page.list.sort_by{ rand }.first))
  end

  def language(name)
    session[:language] = name
    redirect_referrer
  end

  def locale
    session[:language] || Options.for(:wiki).default_language
  end

  private

  # make me public if you dare
  def dot
    dot_plot(Org::Token::LINKS)
    Org::Token::LINKS.clear
    "Plot finished"
  end

  def to_title(string)
    url_decode(string).gsub(/::/, ' ')
  end

  # TODO: Make this more... elegant (maybe using Find.find as base),
  #       no time for that now
  def nested_list(list)
    final = {}

    list.each do |node|
      parts = node.split('/')
      parts.each_with_index do |part, idx|
        ref = final
        idx.times{|i| ref = ref[parts[i]] }
        ref[part] ||= {}
      end
    end

    final_nested_list(final).flatten.join("\n")
  end

  def final_nested_list(list, head = nil)
    list.map do |node, value|
      name = File.join(*[head, node].compact)
      if value.empty?
        "<li>#{list_link(name)}</li>"
      else
        ["<li>#{list_link(name)}</li>",
         "<ul>",
         final_nested_list(value, name),
         "</ul>"]
      end
    end
  end

  def list_link(name)
    a(name, name)
  end

  # Generate a pretty graph from the structure of the wiki and show
  # it, beware of this, as it stops the server until feh returns,
  # useful for development only.
  def dot_plot(links)
    require 'tempfile'

    Tempfile.open('graph.dot') do |dot|
      dot.puts 'Digraph Wiki {'

      links.each do |page, links|
        links.each do |link|
          exists = Page[link.split('#').first].exists?
          color = exists ? '#0000ff' : '#ff0000'
          dot.puts %(  "#{page}" -> "#{link}" [color="#{color}"];)
        end
      end

      dot.puts '}'
      dot.close

      system('dot', '-Tpng', '-O', dot.path)
      system('feh', "#{dot.path}.png")
    end

    Innate::Log.info "Plot finished"
  end
end
