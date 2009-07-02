require File.expand_path('../../../helper', __FILE__)
require 'innate/helper/cgi'

describe "url encode" do
  extend Innate::Helper::CGI

  it 'should url_encode strings' do
    # ok, I believe that the web is dumb for this
    # but this probably is a SHOULD thingy in the HTTP RFC
    url_encode('title with spaces').should == 'title+with+spaces'
    url_encode('[foo]').should == '%5Bfoo%5D'
    u('//').should == '%2F%2F'
  end
  it 'should url_decode strings' do
    url_decode('title%20with%20spaces').should == 'title with spaces'
    url_decode('title+with+spaces').should == 'title with spaces'
  end
  it 'should be reversible' do
    url_decode(u('../ etc/passwd')).should == '../ etc/passwd'
  end
end

describe 'html escape' do
  extend Innate::Helper::CGI

  it 'should escape html' do
    html_escape('& < >').should == '&amp; &lt; &gt;'
    h('<&>').should == '&lt;&amp;&gt;'
  end
  it 'should unescape html' do
    html_unescape('&lt; &amp; &gt;').should == '< & >'
  end
  it 'should be reversible' do
    html_unescape(html_escape('2 > b && b <= 0')).should == '2 > b && b <= 0'
  end
end

