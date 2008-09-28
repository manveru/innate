require 'innate'
require 'innate/setup'
require 'owlscribble'
require 'uv'
require 'git'

Innate.setup do
#   gem :owlscribble
#   gem :uv
#   gem :git

  require 'env', 'model/page', 'node/init'

  start :adapter => :mongrel
end
