require 'spec/helper'

class SessionSpec
  include Innate::Node
  map '/'
  provide :html => :none

  def index
    'No session here'
  end

  def init
    session[:counter] = 0
  end

  def view
    session[:counter]
  end

  def increment
    session[:counter] += 1
  end

  def decrement
    session[:counter] -= 1
  end

  def reset
    session.clear
  end
end

Innate.options.cache.default = Innate::Cache::Memory

Innate.setup_dependencies

describe 'Innate::Session' do
  should 'initiate session as needed' do
    Innate::Mock.session do |session|
      response = session.get('/')
      response.body.should == 'No session here'
      response['Set-Cookie'].should == nil

      session.get('/init').body.should == '0'

      1.upto(10) do |n|
        session.get('/increment').body.should == n.to_s
      end

      session.get('/reset')
      session.get('/view').body.should == ''
      session.get('/init').body.should == '0'

      -1.downto(-10) do |n|
        session.get('/decrement').body.should == n.to_s
      end
    end
  end
end
