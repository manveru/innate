require 'innate'

class Linking
  Innate.node '/'

  def index
    "Index links to " + a('Help?', :help)
  end

  def help
    "Help links to " + Different.a('A Different Node', :another)
  end
end

class Different
  Innate.node '/link_to'

  def another
    a('Another links even deeper', 'and/deeper')
  end

  def and__deeper
    Linking.a('Back to Linking Node', :index)
  end
end

Innate.start
