begin
  require 'fiber'
  require 'innate/core_compatibility/fiber_1.9'
rescue LoadError
  require 'innate/core_compatibility/fiber_1.8'
  require 'innate/core_compatibility/fiber_1.9'
end
