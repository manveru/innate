require File.expand_path('../../helper', __FILE__)

describe Innate::Request do
  def request(env = {})
    Innate::Request.new(@env.merge(env))
  end

  @env = {
    "GATEWAY_INTERFACE"    => "CGI/1.1",
    "HTTP_ACCEPT"          => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "HTTP_ACCEPT_CHARSET"  => "UTF-8,*",
    "HTTP_ACCEPT_ENCODING" => "gzip,deflate",
    "HTTP_ACCEPT_LANGUAGE" => "en-us,en;q=0.8,de-at;q=0.5,de;q=0.3",
    "HTTP_CACHE_CONTROL"   => "max-age=0",
    "HTTP_CONNECTION"      => "keep-alive",
    "HTTP_HOST"            => "localhost:7000",
    "HTTP_KEEP_ALIVE"      => "300",
    "HTTP_USER_AGENT"      => "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.5) Gecko/2008123017 Firefox/3.0.4 Ubiquity/0.1.4",
    "HTTP_VERSION"         => "HTTP/1.1",
    "PATH_INFO"            => "/",
    "QUERY_STRING"         => "a=b",
    "REMOTE_ADDR"          => "127.0.0.1",
    "REMOTE_HOST"          => "delta.local",
    "REQUEST_METHOD"       => "GET",
    "REQUEST_PATH"         => "/",
    "REQUEST_URI"          => "http://localhost:7000/",
    "SCRIPT_NAME"          => "",
    "SERVER_NAME"          => "localhost",
    "SERVER_PORT"          => "7000",
    "SERVER_PROTOCOL"      => "HTTP/1.1",
  }

  should 'provide #request_uri' do
    request('REQUEST_URI' => '/?a=b').request_uri.should == '/?a=b'
    request('REQUEST_URI' => '/').request_uri.should == '/'
  end

  should 'provide #local_net?' do
    request.local_net?('192.168.0.1').to_s.should == '192.168.0.0'
    request.local_net?('252.168.0.1').should == nil
    request.local_net?('unknown').should == nil
    request('REMOTE_ADDR' => '211.3.129.47, 66.249.85.131').local_net?.should == nil
    request('REMOTE_ADDR' => '211.3.129.47').local_net?.should == nil
  end

  should 'provide #subset' do
    require 'stringio'

    query = {'a' => 'b', 'c' => 'd', 'e' => 'f'}
    params = StringIO.new(Rack::Utils.build_query(query))
    req = request('rack.request.form_hash' => params, 'rack.input' => params)

    req.params.should == query
    req.subset(:a).should == {'a' => 'b'}
    req.subset(:a, :c).should == {'a' => 'b', 'c' => 'd'}
  end

  should 'provide #domain on http' do
    request('rack.url_scheme' => 'http').domain.
      should == URI('http://localhost:7000/')

    request('rack.url_scheme' => 'http').domain('/foo').
      should == URI('http://localhost:7000/foo')

    request('rack.url_scheme' => 'http').domain('/foo', :keep_query => true).
      should == URI('http://localhost:7000/foo?a=b')
  end

  should 'provide #domain on https' do
    request('rack.url_scheme' => 'https').domain.
      should == URI('https://localhost:7000/')

    request('rack.url_scheme' => 'https').domain('/foo').
      should == URI('https://localhost:7000/foo')

    request('rack.url_scheme' => 'https').domain('/foo', :keep_query => true).
      should == URI('https://localhost:7000/foo?a=b')
  end
end
