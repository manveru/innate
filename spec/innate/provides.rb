require 'spec/helper'
require 'json'

class SpecNodeBlockProvides
  Innate.node '/provides'

  provide(:yaml){|a,s| ['text/yaml', s.to_yaml] }
  provide(:json){|a,s| ['application/json', s.to_json] }

  def object
    {'intro' => 'Hello, World!'}
  end
end

describe 'Handling content representation' do
  behaves_like :mock

  it 'provides yaml for an object' do
    got = get('/provides/object.yaml')
    got.status.should == 200
    got['Content-Type'].should == 'text/yaml'
    got.body.should == {'intro' => 'Hello, World!'}.to_yaml
  end

  it 'provides json for an object' do
    got = get('/provides/object.json')
    got.status.should == 200
    got['Content-Type'].should == 'application/json'
    got.body.should == {'intro' => 'Hello, World!'}.to_json
  end
end
