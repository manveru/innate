require 'spec/helper'

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
    redirect_referer
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
end

describe Innate::Helper::Redirect do
  behaves_like :mock

  @uri = 'http://localhost:7000'

  should 'retrieve index' do
    get('/').body.should =='SpecRedirectHelper'
  end

  should 'redirect' do
    got = get("#@uri/redirection")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/index"
    got.headers['Content-Type'].should == "text/html"
  end

  should 'redirect twice' do
    got = get("#@uri/double_redirection")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/redirection"
    got.headers['Content-Type'].should == "text/html"
  end

  should 'redirect to referer' do
    got = get("#@uri/redirect_referer_action", 'HTTP_REFERER' => '/noop')
    got.status.should == 302
    got.headers['Location'].should == "#@uri/noop"
    got.headers['Content-Type'].should == "text/html"
    got = get("#@uri/redirect_referer_action", 'HTTP_REFERER' => "#@uri/redirect_referer_action")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/"
    got.headers['Content-Type'].should == "text/html"
  end

  should 'use #r' do
    got = get("#@uri/redirect_method")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/noop"
    got.headers['Content-Type'].should == "text/html"
  end

  should 'work with absolute uris' do
    got = get("#@uri/absolute_redirect")
    got.status.should == 302
    got.headers['Location'].should == "#@uri/noop"
    got.headers['Content-Type'].should == "text/html"
  end

  should 'support #respond' do
    got = get("#@uri/loop")
    got.status.should == 200
    got.body.should == 'no loop'
  end

  should 'support #respond with status' do
    got = get("#@uri/respond_with_status")
    got.status.should == 404
    got.body.should == 'not found'
  end

  should 'support #respond!' do
    got = get("#@uri/destructive_respond")
    got.status.should == 200
    got.body.should == 'destructive'
  end

  should 'redirect without modifying the target' do
    got = get("#@uri/redirect_unmodified")
    got.status.should == 302
    got.headers['Location'].should == '/noop'
  end

  should 'catch redirection' do
    got = get("#@uri/no_actual_redirect")
    got.status.should == 200
    got.body.should == 'no actual redirect'
  end

  should 'catch double redirect' do
    got = get("#@uri/no_actual_double_redirect")
    got.status.should == 200
    got.body.should == 'no actual double redirect'
  end
end
