require 'spec/helper'

class SpecHelperRenderFull
  Innate.node '/render_full'

  def foo
    "foo: %p" % [request.params.sort]
  end

  def standard
    render_full(r(:foo))
  end

  def with_query
    render_full(r(:foo), 'a' => 'b')
  end

  def with_session
    render_full(r(:get_session, :user))
  end

  def get_session(key)
    session[key].inspect
  end

  def set_session(key, value)
    session[key] = value
  end
end

class SpecHelperRenderPartial
  Innate.node '/render_partial'

  layout :layout

  def standard
    'hello'
  end

  def layout
    '{ #{@content} }'
  end

  def without_layout
    render_partial(:standard)
  end
end

class SpecHelperRenderView
  Innate.node '/render_view'
  map_views '/'

  layout :layout

  def standard
    'hello'
  end

  def layout
    '{ #{@content} }'
  end

  def without_method_or_layout
    render_view(:num, :n => 42)
  end
end

class SpecHelperRenderTemplate
  Innate.node '/render_template'

  def relative
    render_template('spec/innate/helper/view/num.xhtml', :n => 42)
  end

  def absolute
    path = File.join(File.dirname(__FILE__), 'view/num.xhtml')
    render_template(path, :n => 42)
  end
end

class SpecHelperRenderMisc
  Innate.node '/misc'
  map_views '/'

  def recursive
    @n ||= 1
  end
end

describe Innate::Helper::Render do
  describe '#render_full' do
    behaves_like :mock, :session

    it 'renders a full action' do
      get('/render_full/standard').body.should == 'foo: []'
    end

    it 'renders full action with query parameters' do
      get('/render_full/with_query').body.should == 'foo: [["a", "b"]]'
    end

    # this is an edge-case, we don't have a full session running if this is the
    # first request from the client as Innate creates sessions only on demand
    # at the end of the request/response cycle.
    #
    # So we have to make some request first, in this case we simply set some
    # value in the session that we can get afterwards.

    it 'renders full action inside a session' do
      session do |mock|
        mock.get('/render_full/set_session/user/manveru')
        mock.get('/render_full/with_session').body.should == '"manveru"'
      end
    end
  end

  describe '#render_partial' do
    behaves_like :mock

    it 'renders action with layout' do
      get('/render_partial/standard').body.should == '{ hello }'
    end

    it 'renders partial action without layout' do
      get('/render_partial/without_layout').body.should == '{ hello }'
    end
  end

  describe '#render_view' do
    behaves_like :mock

    it 'renders action without calling the method or applying layout' do
      get('/render_view/without_method_or_layout').body.should == '{ 42 }'
    end
  end

  describe '#render_template' do
    behaves_like :mock

    it 'renders action with the given template file' do
      get('/render_template/relative').body.should == '42'
      get('/render_template/absolute').body.should == '42'
    end
  end

  describe 'misc functionality' do
    behaves_like :mock

    it 'can render_partial in a loop' do
      get('/misc/loop').body.scan(/\d+/).should == %w[1 2 3 4 5]
    end

    it 'can recursively render_partial' do
      get('/misc/recursive').body.scan(/\S/).join.should == '{1{2{3{44}3}2}1}'
    end
  end
end
