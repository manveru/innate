require 'lib/org'
require 'org/scope/org_mode'
require 'org/to/html'

module Org
  class Token
    include ToHtml
  end
end

require 'bacon'
require 'hpricot'

Bacon.extend(Bacon::TestUnitOutput)
Bacon.summary_on_exit

describe Org::Markup do
  def t(string) # short for transform
    Org::OrgMode.apply(string).to_html
  end

  should 'markup headers' do
    t("* header").should == '<h1>header</h1>'
    t("** header").should == '<h2>header</h2>'
    t("*** header").should == '<h3>header</h3>'
    t("**** header").should == '<h4>header</h4>'
    t("***** header").should == '<h5>header</h5>'
    t("****** header").should == '<h6>header</h6>'
  end

  should 'markup inline' do
    t('*foo*').should == '<p><b>foo</b></p>'
    t('/foo/').should == '<p><i>foo</i></p>'
    t('_foo_').should == '<p><u>foo</u></p>'
    t('+foo+').should == '<p><s>foo</s></p>'
    t('~foo~').should == '<p><blockquote>foo</blockquote></p>'
    t('=foo=').should == '<p><code>foo</code></p>'
  end

  should 'markup table' do
    table = Hpricot(t("|name|address|\n|manveru|home|\n|gojira|tokyo|\n")).at(:table)
    (table/:tr).map{|tr| (tr/:td).map{|td| td.inner_text } }.
      should == [%w[name address], %w[manveru home], %w[gojira tokyo]]
  end

  should 'markup link' do
    t('[[home]]').should == '<p><a href="/home">home</a></p>'
    t('[[home][Home]]').should == '<p><a href="/home">Home</a></p>'
    t('[[http://go.to/]]').should == '<p><a href="http://go.to/">http://go.to/</a></p>'
    t('[[http://go.to/][Go to]]').should == '<p><a href="http://go.to/">Go to</a></p>'
  end
end
