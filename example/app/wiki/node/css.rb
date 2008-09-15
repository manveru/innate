class CSSNode
  include Innate::Node
  map '/css'

  provide :css => :none # serve .css plain
  provide :sass => :sass # serve .css.sass through Sass
end
