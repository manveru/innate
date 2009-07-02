require File.expand_path('../../helper', __FILE__)
require File.expand_path('../../../example/hello', __FILE__)

describe 'example/hello' do
  behaves_like :rack_test

  should 'have index action' do
    got = get('/')
    got.status.should == 200
    got['Content-Type'].should == 'text/html'
    got.body.should == 'Hello, World!'
  end
end
