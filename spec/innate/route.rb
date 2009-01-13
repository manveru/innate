require 'spec/helper'

class SpecRouter
  include Innate::Node
  map '/'
  provide :html => :None

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

Route = Innate::Route

describe Innate::Route do
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
    r = Innate::Mock.get('/123.123')
    r.status.should == 200
    r.body.should == 'Float: 123.123'
  end

  should 'be used at /string' do
    r = Innate::Mock.get('/foo')
    r.status.should == 200
    r.body.should == 'String: foo'
  end

  should 'use %.3f' do
    r = Innate::Mock.get('/123.123456')
    r.status.should == 200
    r.body.should == 'Float: 123.123'
  end

  should 'resolve in the order added' do
    r = Innate::Mock.get('/12.84')
    r.status.should == 200
    r.body.should == 'Price: $12.84'
  end

  should 'use lambda routers' do
    r = Innate::Mock.get('/string/abc')
    r.status.should == 200
    r.body.should == 'String: abc'

    r = Innate::Mock.get('/?do_calc=1&a=2&b=6')
    r.status.should == 200
    r.body.should == '62'
  end

  it 'should support Route() with blocks' do
    r = Innate::Mock.get('/foo?bar=1')
    r.status.should == 200
    r.body.should == 'this is bar'
  end

  it 'should support string route translations' do
    r = Innate::Mock.get('/foobar')
    r.status.should == 200
    r.body.should == 'this is bar'
  end

  it 'should clear routes' do
    Route::ROUTES.size.should > 0
    Route.clear
    Route::ROUTES.size.should == 0
  end

  it 'should exclude existing actions' do
    Innate::Route[ %r!^/(.+)$! ] = "/string/%s"
    r = Innate::Mock.get('/hello')
    r.status.should == 200
    r.body.should == 'String: hello'

    r = Innate::Mock.get('/bar')
    r.status.should == 200
    r.body.should == 'this is bar'
  end

  it 'should not recurse given a bad route' do
    Innate::Route[ %r!^/good/(.+)$! ] = "/bad/%s"
    r = Innate::Mock.get('/good/hi')
    r.status.should == 404
  end
end
