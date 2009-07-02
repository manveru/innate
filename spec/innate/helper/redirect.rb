require File.expand_path('../../../helper', __FILE__)

class SpecRedirectHelper
  Innate.node '/'

  def index
    self.class.name
  end

  def noop
    'noop'
  end

  def redirection
    redirect :index
  end

  def double_redirection
    redirect :redirection
  end

  def redirect_referer_action
    redirect_referer(r(:noop))
  end

  def no_actual_redirect
    catch(:redirect){ redirect(:index) }
    'no actual redirect'
  end

  def no_actual_double_redirect
    catch(:redirect){ double_redirection }
    'no actual double redirect'
  end

  def redirect_method
    redirect r(:noop)
  end

  def absolute_redirect
    redirect 'http://localhost:7000/noop'
  end

  def loop
    respond 'no loop'
    'loop'
  end

  def respond_with_status
    respond 'not found', 404
  end

  def destructive_respond
    respond! 'destructive'
  end

  def redirect_unmodified
    raw_redirect '/noop'
  end

  def redirect_with_cookie
    response.set_cookie('user', :value => 'manveru')
    redirect r(:noop)
  end
end

describe Innate::Helper::Redirect do
  behaves_like :rack_test

  @uri = 'http://localhost:7000'

  should 'retrieve index' do
    get('/').body.should =='SpecRedirectHelper'
  end

  should 'redirect' do
    get("#@uri/redirection")

    last_response.status.should == 302
    last_response.headers['Location'].should == "#@uri/index"
    last_response.headers['Content-Type'].should == "text/html"
  end

  should 'redirect twice' do
    get("#@uri/double_redirection")

    last_response.status.should == 302
    last_response.headers['Location'].should == "#@uri/redirection"
    last_response.headers['Content-Type'].should == "text/html"
  end

  should 'redirect to referer' do
    header 'HTTP_REFERER', '/index'
    get("#@uri/redirect_referer_action")

    last_response.status.should == 302
    last_response.headers['Location'].should == "#@uri/index"
    last_response.headers['Content-Type'].should == "text/html"
  end

  should 'redirect to fallback if referrer is identical' do
    header 'HTTP_REFERER', "#@uri/redirect_referer_action"
    get("#@uri/redirect_referer_action")

    last_response.status.should == 302
    last_response.headers['Location'].should == "#@uri/noop"
    last_response.headers['Content-Type'].should == "text/html"
  end

  should 'use #r' do
    get("#@uri/redirect_method")

    last_response.status.should == 302
    last_response.headers['Location'].should == "#@uri/noop"
    last_response.headers['Content-Type'].should == "text/html"
  end

  should 'work with absolute uris' do
    get("#@uri/absolute_redirect")

    last_response.status.should == 302
    last_response.headers['Location'].should == "#@uri/noop"
    last_response.headers['Content-Type'].should == "text/html"
  end

  should 'support #respond' do
    get("#@uri/loop")

    last_response.status.should == 200
    last_response.body.should == 'no loop'
  end

  should 'support #respond with status' do
    get("#@uri/respond_with_status")

    last_response.status.should == 404
    last_response.body.should == 'not found'
  end

  should 'support #respond!' do
    get("#@uri/destructive_respond")

    last_response.status.should == 200
    last_response.body.should == 'destructive'
  end

  should 'redirect without modifying the target' do
    get("#@uri/redirect_unmodified")

    last_response.status.should == 302
    last_response.headers['Location'].should == '/noop'
  end

  should 'catch redirection' do
    get("#@uri/no_actual_redirect")
    last_response.status.should == 200
    last_response.body.should == 'no actual redirect'
  end

  should 'catch double redirect' do
    get("#@uri/no_actual_double_redirect")
    last_response.status.should == 200
    last_response.body.should == 'no actual double redirect'
  end

  should 'set cookie before redirect' do
    get("#@uri/redirect_with_cookie")
    follow_redirect!
    last_request.cookies.should == {'user' => 'manveru'}
  end
end
