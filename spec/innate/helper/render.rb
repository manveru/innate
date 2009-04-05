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

  def standard
    'hello'
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

    it 'renders a partial action without layout' do
      get('/render_partial/standard').body.should == 'hello'
    end
  end
end
