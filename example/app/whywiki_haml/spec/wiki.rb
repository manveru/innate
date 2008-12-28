require 'innate'
require 'innate/spec'
require 'yaml/store'

base = File.join(File.dirname(__FILE__), '..')
DB = YAML::Store.new(db_file = "#{base}/spec/wiki.yaml")

require "start"

Innate.config.app.root = base

describe 'Wiki' do
  it 'should have index page' do
    page = Innate::Mock.get('/')
    page.body.should == ''
  end

  FileUtils.rm_f(db_file)
end
