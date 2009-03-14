$0 = caller.last[/^[^:]+/] unless caller.empty?

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/innate'))
require 'innate/spec'
