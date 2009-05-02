# The minimal _why wiki in Innate with ERB

%w[rubygems innate erb maruku yaml/store].each{|l| require(l) }

DB = YAML::Store.new('wiki.yaml') unless defined?(DB)

class Wiki
  Innate.node '/'
  layout 'wiki'
  provide :html, :engine => :ERB

  def index(page = 'Home')
    @page = page
    @text = 'foo'
    sync{
      @text = DB[page].to_s.dup
      @text.gsub!(/\[\[(.*?)\]\]/) do
        %(<a href="#{r($1)}" class="#{DB[$1] ? 'exists' : 'missing'}">#{h($1)}</a>)
      end
    }
  end

  def edit(page)
    @page = page
    @text = sync{ DB[page].to_s }
  end

  def save
    page, text = request[:page, :text]
    sync{ DB[page] = text } if request.post? and page and text

    redirect(r(page))
  end

  private

  def sync
    Innate.sync{ DB.transaction{ yield }}
  end
end

Innate.start
