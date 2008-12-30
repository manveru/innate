require 'lib/innate/core_compatibility/basic_object'
require 'lib/innate/option'

require 'bacon'

Bacon.extend(Bacon::TestUnitOutput)
Bacon.summary_on_exit

Options = Innate::Options

describe Options do
  should 'create scope' do
    Options.for :site do |site|
      site.title = 'araiguma'

      site.admin do |admin|
        admin.name = 'manveru'
        admin.pass = 'letmein'
      end

      site.db = 'sqlite'
    end

    Options.for(:site).title.should == 'araiguma'
  end

  should 'inherit scope' do
    Options.for(:site).admin.title.should == 'araiguma'
  end

  should 'access scope by for' do
    Options.for(:site).admin.name.should == 'manveru'
    Options.for('site:admin').name.should == 'manveru'
  end

  should 'replace scope with value' do
    Options.for(:site).db = 1
    Options.for(:site).db.should == 1
    Options::SCOPE['site:db'].should == nil
  end

  should 'replace value with scope' do
    Options.for(:site).db do |db|
      db.logging = true
    end

    Options.for(:site).db.logging.should == true
  end

  should 'iterate options' do
    expect = %w[admin db title]

    Options.each(:site) do |key, value|
      expect.delete key
    end

    expect.should.be.empty
  end
end
