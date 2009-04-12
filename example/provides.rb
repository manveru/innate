require 'rubygems'
require 'innate'
require 'yaml'

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
  # If you request `/list.yaml`, you will get the `ARTICLES object serialized
  # to YAML.
  provide(:yaml, :type => 'text/yaml'){|action, value| value.to_yaml }

  # Since there will always be an `html` representation (the default), you have
  # to take care of it. If you simply want to return an empty page, use following.
  provide(:html){|action, value| '' }

  # The return value of this method is the `value` in the provides above.
  def list
    return ARTICLES
  end
end

Innate.start
