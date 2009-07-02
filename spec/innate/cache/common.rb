Innate::Cache.options.names = [:one, :two]
Innate::Cache.options.one = $common_cache_class
Innate::Cache.options.two = $common_cache_class
Innate.setup_dependencies

describe $common_cache_class do
  cache = Innate::Cache.one

  @hello = 'Hello, World!'

  should 'store without ttl' do
    cache.store(:hello, @hello).should == @hello
  end

  should 'fetch' do
    cache.fetch(:hello).should == @hello
  end

  should 'delete' do
    cache.delete(:hello)
    cache.fetch(:hello).should == nil
  end

  should 'delete two key/value pairs at once' do
    cache.store(:hello, @hello).should == @hello
    cache.store(:innate, 'innate').should == 'innate'
    cache.delete(:hello, :innate)
    cache.fetch(:hello).should == nil
    cache.fetch(:innate).should == nil
  end

  should 'store with ttl' do
    cache.store(:hello, @hello, :ttl => 0.2)
    cache.fetch(:hello).should == @hello
    sleep 0.3
    cache.fetch(:hello).should == nil
  end

  should 'clear' do
    cache.store(:hello, @hello)
    cache.fetch(:hello).should == @hello
    cache.clear
    cache.fetch(:hello).should == nil
  end
end
