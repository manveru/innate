require 'spec/helper'
require 'example/provides'

describe 'examples/provide' do
  behaves_like :rack_test

  it 'provides YAML representation' do
    get '/list.yaml'
    last_response.body.should == ARTICLES.to_yaml
    last_response['Content-Type'].should == 'text/yaml'

    get '/list'
    last_response.body.should == ''
    last_response['Content-Type'].should == 'text/html'
  end
end
