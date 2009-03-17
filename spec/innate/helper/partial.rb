require 'spec/helper'

class SpecHelperPartial
  Innate.node '/'
  map_views '/'

  def index
    '<html><head><title><%= render_partial("/title") %></title></head></html>'
  end

  def title
    "Title"
  end

  def with_params
    '<html><head><title><%= render_partial("/message", :msg => "hello") %></title></head></html>'
  end

  def message
    "Message: #{request[:msg]}"
  end

  def without_ext
    render_template('partial')
  end

  def with_real_ext
    render_template('partial.erb')
  end

  def with_needed_ext
    render_template('partial.html')
  end

  def composed
    @here = 'there'
    'From Action | ' << render_template("partial")
  end

  def recursive
    @n = 1
  end

  def with_variable
    here = 'there'
    render_template("partial", :here => here)
  end
end

class SpecHelperPartialWithLayout < SpecHelperPartial
  Innate.node '/with_layout'
  layout('layout')

  def layout
    '<h1>with layout</h1><%= @content %>'
  end
end

describe Innate::Helper::Partial do
  behaves_like :mock

  should 'render partials' do
    get('/').body.should == '<html><head><title>Title</title></head></html>'
  end

  should 'render partials with params' do
    get('/with_params').body.should == '<html><head><title>Message: hello</title></head></html>'
  end

  should 'be able to render a template in the current scope' do
    get('/composed').body.strip.should == "From Action | From Partial there"
  end

  should 'not require file extension' do
    get('/without_ext').body.should == "From Partial \n"
  end

  it "the real extension will just be stripped" do
    got = get('/with_real_ext').body.should == "From Partial \n"
  end

  it "works with the content representation instead" do
    get('/with_needed_ext').body.should == "From Partial \n"
  end

  should 'render_template in a loop' do
    get('/loop').body.gsub(/\s/,'').should == '12345'
  end

  should 'work recursively' do
    get('/recursive').body.gsub(/\s/,'').should == '{1{2{3{44}4}3}2}'
  end

  should 'render template with layout' do
    get('/with_layout/without_ext').body.should == "<h1>with layout</h1>From Partial \n"
  end

  it 'makes passed variables available in the template as instance variables' do
    get('/with_variable').body.should == "From Partial there\n"
  end
end
