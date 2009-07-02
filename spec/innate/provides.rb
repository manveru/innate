require File.expand_path('../../helper', __FILE__)

require 'json'
require 'yaml'

Innate.options.merge!(:views => 'provides', :layouts => 'provides')

class SpecNodeProvides
  Innate.node '/'

  provide(:html, :engine => :None)
  provide(:yaml, :type => 'text/yaml'){|a,s| s.to_yaml }
  provide(:json, :type => 'application/json'){|a,s| s.to_json }

  def object
    {'intro' => 'Hello, World!'}
  end

  def string
    'Just 42'
  end
end

class SpecNodeProvidesTemplates
  Innate.node '/template'
  map_views '/'

  provide(:yaml, :type => 'text/yaml'){|a,s| s.to_yaml }
  provide(:json, :type => 'application/json'){|a,s| s.to_json }
  provide(:txt, :engine => :Etanni, :type => 'text/plain')

  def list
    @users = %w[starbucks apollo athena]
  end
end

shared :assert_wish do
  def assert_wish(uri, body, content_type)
    got = get(uri)
    got.status.should == 200
    got.body.strip.should == body.strip
    got['Content-Type'].should == content_type
  end
end

describe 'Content representation' do
  describe 'without template' do
    behaves_like :rack_test, :assert_wish

    it 'provides yaml for an object' do
      assert_wish('/object.yaml', {'intro' => 'Hello, World!'}.to_yaml, 'text/yaml')
    end

    it 'provides json for an object' do
      assert_wish('/object.json', {'intro' => 'Hello, World!'}.to_json, 'application/json')
    end

    it 'provides html for an object' do
      assert_wish('/string.html', 'Just 42', 'text/html')
    end

    it 'defaults to html presentation' do
      assert_wish('/string', 'Just 42', 'text/html')
    end
  end

  describe 'with templates' do
    behaves_like :rack_test, :assert_wish

    it 'defaults to <name>.html.<engine>' do
      body = '<ul><li>starbucks</li><li>apollo</li><li>athena</li></ul>'
      assert_wish('/template/list', body, 'text/html')
    end

    it 'uses explicit wish for <name>.html.<engine>' do
      body = '<ul><li>starbucks</li><li>apollo</li><li>athena</li></ul>'
      assert_wish('/template/list.html', body, 'text/html')
    end

    it 'fails when the wish cannot be satisfied' do
      got = get('/template/list.svg')
      got.status.should == 404
    end

    it 'uses the object returned from the action method for block provides' do
      body = %w[starbucks apollo athena].to_yaml
      assert_wish('/template/list.yaml', body, 'text/yaml')
    end

    it 'uses explicit wish for <name>.txt.<engine>' do
      body = "starbucks\napollo\nathena"
      assert_wish('/template/list.txt', body, 'text/plain')
    end
  end
end
