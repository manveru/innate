require 'innate'

class Hello
  include Innate::Node
  map '/'

  helper :link, :cgi

  provide :html => :haml

  TEMPLATE = '
!!! XML
!!!
%html
  %head
    %title Session example
  %body
    %h1 Session example
    = "Value is #{session[:value]}"
    %br/
    = a :increment
    %br/
    = a :decrement
'.strip

  def index
    session[:value] = 0
    TEMPLATE
  end

  def increment
    session[:value] += 1 if session[:value]
    TEMPLATE
  end

  def decrement
    session[:value] -= 1 if session[:value]
    TEMPLATE
  end
end

Innate.start
