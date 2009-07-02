if caller_line = caller.grep(%r!spec/innate/!).first
  caller_file = caller_line.split(':', 2).first
  caller_root = File.dirname(caller_file)
  $0 = caller_file
end

require File.expand_path('../../lib/innate', __FILE__)
require 'innate/spec'

Innate.options.roots = [caller_root] if caller_root
