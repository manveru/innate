class PageNode
  include Innate::Node
  map '/'
  layout 'page'

  provide :html => :haml

  def index(name = 'Home')
    @page = Page[name]
    @name = name
    @title = name.dewikiword
    @text = @page.render
  end

  def edit(name)
    @save_action = r :save, name
    @move_action = r :move, name
    @name = name
    @page = Page[name]
    @title = name.dewikiword
    @text = @page.content
  end

  def save(name)
    @page = Page[name]

    if text = request.params['text']
      comment = @page.exists? ? "Edit #{name}" : "Create #{name}"
      @page.save(text, comment)
    end

    redirect rs(name)
  end

  def move(from)
    if to = request.params['move']
      Page[from].move(to)
      redirect rs(to)
    end

    redirect rs(from)
  end

  def delete(name)
    Page[name].delete

    redirect rs(:/)
  end

  def list
    Page.list
  end
end
