require File.expand_path('../../../helper', __FILE__)

class SpecFlash
  include Innate::Node
  map '/'

  def welcome
    flash[:name] = 'manveru'
    "Welcome #{flash[:name]}"
  end

  def bye
    "Bye #{flash[:name]}"
  end

  def check_empty
    flash.empty?.to_s
  end

  def set_delete_key
    flash[:name] = 'manveru'
    flash.delete(:name)
    flash[:name].to_s
  end

  def delete_key
    flash.delete(:name)
    "Bye #{flash[:name]}"
  end

  def merge!
    flash.merge!(:name => 'feagliir').inspect
  end

  def merge
    flash.merge(:name => 'feagliir').inspect
  end

  def inspect
    flash[:yes] = :yeah
    flash.inspect
  end

  def iterate
    flash[:yes] = :yeah
    elems = []
    flash.each{|k,v| elems << [k,v] }
    elems.inspect
  end
end

class SpecFlashSub < SpecFlash
  map '/sub'
end

describe Innate::Helper::Flash do
  behaves_like :rack_test

  should 'set and forget flash twice' do
    get('/welcome').body.should == 'Welcome manveru'
    get('/bye').body.should == 'Bye manveru'
    get('/bye').body.should == 'Bye'

    get('/welcome').body.should == 'Welcome manveru'
    get('/bye').body.should == 'Bye manveru'
    get('/bye').body.should == 'Bye'
  end

  should 'work over multiple nodes' do
    get('/welcome').body.should == 'Welcome manveru'
    get('/sub/bye').body.should == 'Bye manveru'
    get('/sub/bye').body.should == 'Bye'

    get('/sub/welcome').body.should == 'Welcome manveru'
    get('/bye').body.should == 'Bye manveru'
    get('/bye').body.should == 'Bye'
  end

  should 'check if flash is empty' do
    get('/welcome').body.should == 'Welcome manveru'
    get('/check_empty').body.should == 'false'
    get('/check_empty').body.should == 'true'
  end

  should 'set and delete key within one request' do
    get('/set_delete_key').body.should == ''
  end

  should 'set and delete key over two request' do
    get('/welcome').body.should == 'Welcome manveru'
    get('/delete_key').body.should == 'Bye'
  end

  should 'merge with hash' do
    get('/merge').body.should == {:name => 'feagliir'}.inspect
    get('/bye').body.should == 'Bye'
  end

  should 'merge! with hash' do
    get('/merge!').body.should == {:name => 'feagliir'}.inspect
    get('/bye').body.should == 'Bye feagliir'
  end

  should 'inspect combined' do
    get('/welcome')
    get('/inspect').body.should == {:name => 'manveru', :yes => :yeah}.inspect
  end

  should 'iterate over combined' do
    get('/welcome')

    hash = {:yes => :yeah, :name => 'manveru'}
    Hash[*eval(get('/iterate').body).flatten].should == hash
  end
end
