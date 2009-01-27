# The minimal _why wiki in Innate

%w[rubygems innate erb maruku yaml/store].each{|l| require(l) }

DB = YAML::Store.new('wiki.yaml') unless defined?(DB)

class Wiki
  include Innate::Node
  map '/'
  provide :html => :erb
  layout 'wiki'

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
    redirect_referrer unless request.post?

    page, text = request[:page, :text]
    sync{ DB[page] = text } if page and text

    redirect(r(page))
  end

  private

  def sync
    Innate::STATE.sync{ DB.transaction{ yield }}
  end
end

Innate.start :adapter => :mongrel
