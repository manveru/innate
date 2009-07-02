require File.expand_path('../../helper', __FILE__)
require File.expand_path('../../../example/link', __FILE__)

describe 'example/link' do
  behaves_like :rack_test

  should 'have index on Linking' do
    get('/').body.should == 'Index links to <a href="/help">Help?</a>'
  end

  should 'have help on Linking' do
    get('/help').body.should ==
      "Help links to <a href=\"/link_to/another\">A Different Node</a>"
  end

  should 'have another on Different' do
    get('/link_to/another').body.
      should == "<a href=\"/link_to/and/deeper\">Another links even deeper</a>"
  end

  should 'have and__deeper on Different' do
    get('/link_to/and/deeper').body.
      should == "<a href=\"/index\">Back to Linking Node</a>"
  end
end
