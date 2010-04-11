require File.expand_path('../../helper', __FILE__)
require 'innate/view/etanni'

describe Etanni = Innate::Etanni do
  it 'renders a simple template' do
    etanni = Etanni.new('Hello, World!')
    etanni.result(self).should == 'Hello, World!'
  end

  it 'allows use of Etanni::SEPARATOR inside interplated code' do
    etanni = Etanni.new('Hello #{@name}')
    @name = "\n#{Etanni::SEPARATOR}\n"
    etanni.result(self).should == "Hello #{@name}"
  end

  it 'fails with SyntaxError or NameError when the SEPARATOR is used inside a template' do
    lambda{
      etanni = Etanni.new("Hello \n#{Etanni::SEPARATOR}\n")
      etanni.result(self)
    }.should.raise NameError

    lambda{
      etanni = Etanni.new("<h1>Hello \n#{Etanni::SEPARATOR}\n</h1>")
      etanni.result(self)
    }.should.raise SyntaxError
  end
end
