require 'innate'

class Hello
  Innate.node '/'

  TEMPLATE = '
<html>
  <head>
    <title>Session example</title>
  </head>
  <body>
    <h1>Session example</h1>
    <p>
      Value is: #{ session[:value] }<br />
      #{ a :increment }<br />
      #{ a :decrement }
    </p>
  </body>
</html>
'.strip

  def index
    session[:value] = 0
    TEMPLATE
  end

  def increment
    session[:value] = session[:value].to_i + 1
    TEMPLATE
  end

  def decrement
    session[:value] = session[:value].to_i - 1
    TEMPLATE
  end
end

Innate.start
