# We define BasicObject for compatibility with 1.9 if it isn't there yet.
class BasicObject
  # Remove all but these methods
  # NOTE: __id__ is not there in 1.9, but would give a warning in 1.8
  KEEP = %w[== equal? ! != instance_eval instance_exec __send__ __id__]

  (instance_methods - KEEP).each do |im|
    undef_method(im)
  end
end unless defined?(BasicObject)
