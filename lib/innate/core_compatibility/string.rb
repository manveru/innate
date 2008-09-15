class String # Dirty hack, but Rack needs it?
  alias each each_line unless 'String'.respond_to?(:each)
end
