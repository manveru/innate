require 'rubygems'
require 'innate'

ARTICLES = {
  'hello' => {
    :author => 'manveru',
    :title => 'Hello, World!',
    :text => 'Some text'
  }
}

class BlogArticles
  Innate.node('/')

  # provide a content representation for requests to /<action>.yaml
  provide(:yaml, :type => 'text/yaml'){|action, value| value.to_yaml }

  # the return value of this method is the `value` in the provide above
  # Since ruby has implicit returns, `ARTICLES` will be the return value.
  #
  # If you request `/list.yaml` you will get the `ARTICLES` object serialized
  # to YAML.
  def list
    @articles = ARTICLES
  end
end

Innate.start
