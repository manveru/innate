require File.expand_path('../../../helper', __FILE__)

class SpecSendFile
  include Innate::Node
  map '/'

  def this
    send_file(__FILE__)
  end
end

describe Innate::Helper::SendFile do
  should 'send __FILE__' do
    got = Innate::Mock.get('/this')

    got.body.should == File.read(__FILE__)
    got.status.should == 200
    got['Content-Length'].should == File.size(__FILE__).to_s
    got['Content-Type'].should == 'text/x-script.ruby'
  end
end
