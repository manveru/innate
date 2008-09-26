require 'innate'
require 'yaml/store'

STORE = YAML::Store.new('games.yaml')

def STORE.[](key) transaction{|s| s[key] } end
def STORE.[]=(key, value) transaction{|s| s[key] = value } end
def STORE.each
  YAML.load_file('games.yaml').sort_by{|k,v| -v }.each{|(k,v)| yield(k, v) }
end

class Games
  include Innate::Node
  map '/'
  provide :html => :haml

  def index
    TEMPLATE
  end

  def create
    if request.post?
      name = request.params['name']
      STORE[name] ||= 0
    end

    redirect_referrer
  end

  def vote(name)
    STORE[url_decode name] += 1

    redirect_referrer
  end

  TEMPLATE = <<-'T'.strip
!!! XML
!!!

%html
  %head
    %title Top Retro Games
  %body
    %h1 Vote on your favorite Retro Game
    %form{:action => r(:create), :method => 'POST'}
      %input{:type => 'text', :name => 'name'}
      %input{:type => 'submit', :value => 'Add'}
    %ol
      - STORE.each do |name, votes|
        %li
          = Games.a("Vote", "/vote/#{u name}")
          = h("%5d => %s" % [votes, name])
  T

end

Innate.start
