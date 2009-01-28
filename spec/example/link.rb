require 'spec/helper'
require 'example/link'

describe 'example/link' do
  behaves_like :mock

  should 'have index on Linking' do
    get('/').body.should == 'simple link<br /><a href="/help">Help?</a>'
  end

  should 'have new on Linking' do
    get('/new').body.should == 'Something new!'
  end

  should 'have help on Linking' do
    get('/help').body.should ==
      "You have help<br /><a href=\"/link_to/another\">A Different Node</a>"
  end

  should 'have another on Different' do
    get('/link_to/another').body.
      should == "<a href=\"/link_to/and/deeper\">Even deeper</a>"
  end

  should 'have and__deeper on Different' do
    get('/link_to/and/deeper').body.
      should == "<a href=\"/index\">Back to Linking Node</a>"
  end
end
