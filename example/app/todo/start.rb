require 'rubygems'
require 'innate'
require 'pstore'

LIST = PStore.new('todo.pstore')

class Todo
  Innate.node '/'
  layout 'default'

  def index
    @list = sync{|list| list.roots.map{|key| [key, list[key]] }}
  end

  def create
    redirect_referer unless request.post? and title = request[:title]
    title.strip!

    sync{ LIST[title] = false } unless title.empty?
    redirect_referer
  end

  def update
    id, title, done = request[:id, :title, :done]
    redirect_referer unless request.post? and id and title
    done = !!done
    title.strip!

    if id == title
      sync{ LIST[id] = done }
    elsif title != ''
      sync{ LIST.delete(id); LIST[title] = done }
    end

    redirect_referer
  end

  def delete
    redirect_referer unless request.post? and id = request[:id]
    sync{ LIST.delete(id) }
    redirect_referer
  end

  private

  def sync
    Innate.sync{ LIST.transaction{ yield(LIST) }}
  end
end

Innate.start
