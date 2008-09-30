require 'innate'

# This demonstrates how to obtain different content types from the return value
# of action methods.
#
# Try following requests:
#   /set/foo/bar
#   /set/duh/duf
#
#   /index.json
#   /index.yaml
#
#   /get/foo.json
#   /get/foo.yaml
# 
# Note that this functionality is quite experimental, but by strategically
# placing ressources in actions it may be possible to achieve interesting
# effects and interoperability with JavaScript at a low cost.
#
# TODO:
#   * parsing requests based on the content-type, but that's much less
#     straight-forward and would require some kind of convention?

class Dict
  include Innate::Node
  map '/'

  DICT = {}

  # /get/foo || /get/foo.json || /get/foo.yaml
  def get(key)
    {key => DICT[key]}
  end

  # /set/foo/bar || /set/foo/bar.json || /set/foo/bar.yaml
  def set(key, value)
    {key => (DICT[key] = value)}
  end

  # /index.json || /.json || /index.yaml || /.yaml
  def index
    DICT
  end
end

Innate.start
