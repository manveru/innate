require 'spec/helper'
require 'example/app/retro_games'

describe 'Retro-games app' do
  behaves_like :mock

  it 'lists the first game' do
    get '/'
    last_response.should =~ /1 =&gt; Pacman/
  end

  it 'has a form to add another game' do
    get '/'
    last_response.should =~ /<form/
  end

  it 'allows you to add another game' do
    post '/create', :name => 'Street Fighter II'
    follow_redirect!
    last_response.should =~ /0 =&gt; Street Fighter II/
  end

  it 'allows you to vote for a game' do
    get '/vote/Street+Fighter+II'
    follow_redirect!
    last_response.should =~ /1 =&gt; Street Fighter II/
  end

  FileUtils.rm_f('games.yaml')
end
