require 'spec/helper'
require 'example/hello'

describe 'example/hello' do
  behaves_like :rack_test

  should 'have index action' do
    got = get('/')
    got.status.should == 200
    got['Content-Type'].should == 'text/html'
    got.body.should == 'Hello, World!'
  end
end
