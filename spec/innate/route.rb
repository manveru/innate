require File.expand_path('../../helper', __FILE__)

class SpecRouter
  Innate.node('/').provide(:html, :None)

  def float(flt)
    "Float: %3.3f" % flt
  end

  def string(str)
    "String: #{str}"
  end

  def price(p)
    "Price: \$#{p}"
  end

  def sum(a, b)
    a.to_i + b.to_i
  end

  def bar
    'this is bar'
  end
end

Route, Rewrite = Innate::Route, Innate::Rewrite

describe Innate::Route do
  def check(uri, status, body = nil)
    got = Innate::Mock.get(uri)
    got.status.should == status
    got.body.should == body if body
  end

  should 'take lambda routers' do
    Route['string'] = lambda{|path, req|
      path if path =~ %r!^/string!
    }
    Route['string'].class.should == Proc

    Route['calc sum'] = lambda{|path, req|
      if req[:do_calc]
        lval, rval = req[:a, :b]
        rval = rval.to_i * 10
        "/sum/#{lval}/#{rval}"
      end
    }

    Innate::Route('foo') do |path, req|
      '/bar' if req[:bar]
    end
  end

  should 'define string routes' do
    Route['/foobar'] = '/bar'
    Route['/foobar'].should == '/bar'
  end

  should 'define regex routes' do
    Route[%r!^/(\d+\.\d{2})$!] = "/price/%.2f"
    Route[%r!^/(\d+\.\d{2})$!].should == "/price/%.2f"

    Route[%r!^/(\d+\.\d+)!] = "/float/%.3f"
    Route[%r!^/(\d+\.\d+)!].should == "/float/%.3f"

    Route[%r!^/(\w+)!] = "/string/%s"
    Route[%r!^/(\w+)!].should == "/string/%s"
  end

  should 'be used at /float' do
    check('/123.123', 200, 'Float: 123.123')
  end

  should 'be used at /string' do
    check('/foo', 200, 'String: foo')
  end

  should 'use %.3f' do
    check('/123.123456', 200, 'Float: 123.123')
  end

  should 'resolve in the order added' do
    check('/12.84', 200, 'Price: $12.84')
  end

  should 'use lambda routers' do
    check('/string/abc', 200, 'String: abc')

    check('/?do_calc=1&a=2&b=6', 200, '62')
  end

  it 'should support Route() with blocks' do
    check('/foo?bar=1', 200, 'this is bar')
  end

  it 'should support string route translations' do
    check('/foobar', 200, 'this is bar')
  end

  it 'should clear routes' do
    Route::ROUTES.size.should > 0
    Route.clear
    Route::ROUTES.size.should == 0
  end

  it 'should not recurse given a bad route' do
    Innate::Route[ %r!^/good/(.+)$! ] = "/bad/%s"
    check('/good/hi', 404)
  end
end

describe Innate::Rewrite do
  Innate::Rewrite[ %r!^/(.+)$! ] = "/string/%s"

  it 'should rewrite on non-existent actions' do
    got = Innate::Mock.get('/hello')
    got.status.should == 200
    got.body.should == 'String: hello'
  end

  it 'should exclude existing actions' do
    got = Innate::Mock.get('/bar')
    got.status.should == 200
    got.body.should == 'this is bar'
  end

  it 'should rewite with (key, val)' do
    Innate::Rewrite[ %r!^/(.+)$! ] = nil
    Innate::Rewrite(%r!^/(.+)$!, "/string/%s")
    got = Innate::Mock.get('/hello')
    got.status.should == 200
    got.body.should == 'String: hello'
  end
end
