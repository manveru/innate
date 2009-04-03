#          Copyright (c) 2009 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'spec/helper'

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
  behaves_like :session

  should 'set and forget flash twice' do
    session do |mock|
      mock.get('/welcome').body.should == 'Welcome manveru'
      mock.get('/bye').body.should == 'Bye manveru'
      mock.get('/bye').body.should == 'Bye'

      mock.get('/welcome').body.should == 'Welcome manveru'
      mock.get('/bye').body.should == 'Bye manveru'
      mock.get('/bye').body.should == 'Bye'
    end
  end

  should 'work over multiple nodes' do
    session do |mock|
      mock.get('/welcome').body.should == 'Welcome manveru'
      mock.get('/sub/bye').body.should == 'Bye manveru'
      mock.get('/sub/bye').body.should == 'Bye'

      mock.get('/sub/welcome').body.should == 'Welcome manveru'
      mock.get('/bye').body.should == 'Bye manveru'
      mock.get('/bye').body.should == 'Bye'
    end
  end

  should 'check if flash is empty' do
    session do |mock|
      mock.get('/welcome').body.should == 'Welcome manveru'
      mock.get('/check_empty').body.should == 'false'
      mock.get('/check_empty').body.should == 'true'
    end
  end

  should 'set and delete key within one request' do
    session do |mock|
      mock.get('/set_delete_key').body.should == ''
    end
  end

  should 'set and delete key over two request' do
    session do |mock|
      mock.get('/welcome').body.should == 'Welcome manveru'
      mock.get('/delete_key').body.should == 'Bye'
    end
  end

  should 'merge with hash' do
    session do |mock|
      mock.get('/merge').body.should == {:name => 'feagliir'}.inspect
      mock.get('/bye').body.should == 'Bye'
    end
  end

  should 'merge! with hash' do
    session do |mock|
      mock.get('/merge!').body.should == {:name => 'feagliir'}.inspect
      mock.get('/bye').body.should == 'Bye feagliir'
    end
  end

  should 'inspect combined' do
    session do |mock|
      mock.get('/welcome')
      mock.get('/inspect').body.
        should == {:name => 'manveru', :yes => :yeah}.inspect
    end
  end

  should 'iterate over combined' do
    session do |mock|
      mock.get('/welcome')

      hash = {:yes => :yeah, :name => 'manveru'}
      Hash[*eval(mock.get('/iterate').body).flatten].should == hash
    end
  end
end
