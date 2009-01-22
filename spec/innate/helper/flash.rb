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

  def box
    flashbox
  end

  def check_empty
    flash.empty?.to_s
  end

  def set(*hash)
    Hash[*hash].each do |key, value|
      flash[key] = value
    end
    hash.inspect
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
      mock.get('/bye').body.should == 'Bye '

      mock.get('/welcome').body.should == 'Welcome manveru'
      mock.get('/bye').body.should == 'Bye manveru'
      mock.get('/bye').body.should == 'Bye '
    end
  end

  should 'work over multiple nodes' do
    session do |mock|
      mock.get('/welcome').body.should == 'Welcome manveru'
      mock.get('/sub/bye').body.should == 'Bye manveru'
      mock.get('/sub/bye').body.should == 'Bye '

      mock.get('/sub/welcome').body.should == 'Welcome manveru'
      mock.get('/bye').body.should == 'Bye manveru'
      mock.get('/bye').body.should == 'Bye '
    end
  end

  should 'check if flash is empty' do
    session do |mock|
      mock.get('/welcome').body.should == 'Welcome manveru'
      mock.get('/check_empty').body.should == 'false'
      mock.get('/check_empty').body.should == 'true'
    end
  end
end
