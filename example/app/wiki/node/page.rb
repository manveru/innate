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
    @action = "/save/#{name}"
    @page = Page[name]
    @title = name.dewikiword
    @text = @page.content
    p :@text => @text
  end

  def save(name)
    @page = Page[name]

    if text = request.params['text']
      comment = @page.exists? ? "Edit #{name}" : "Create #{name}"
      @page.save(text, comment)
    end

    redirect "/index/#{name}"
  end

  def list
    Page.list
  end

  def redirect(target)
    response.status = 302
    response['location'] = target
    response.write %{You are being redirected, please follow <a href="#{target}">this link to:#{target}</a>!}
    throw :respond
  end
end
