require 'innate'

class Linking
  include Innate::Node
  map '/'

  def index
    "simple link<br />" +
      a('Help?', :help)
  end

  def new
    "Something new!"
  end

  def help
    "You have help<br />" +
      Different.a('A Different Node', :another)
  end
end

class Different
  include Innate::Node
  map '/link_to'

  def another
    a('Even deeper', 'and/deeper')
  end

  def and__deeper
    Linking.a('Back to Linking Node', :index)
  end
end

Innate.start
