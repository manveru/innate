require File.expand_path('../../helper', __FILE__)

class Animal
  include Innate::Traited
end

class Cat < Animal
end

class Tiger < Animal
end

describe Innate::Traited do
  should 'set trait on superclass' do
    Animal.trait :wild => :depends
    Animal.trait[:wild].should == :depends
  end

  should 'reset trait on superclass' do
    Animal.trait :wild => :naturally
    Animal.trait[:wild].should == :naturally
  end

  should 'set trait on instance' do
    animal = Animal.new
    animal.trait[:wild].should == nil
    animal.trait :wild => :depends
    animal.trait[:wild].should == :depends
  end

  should 'get ancestral trait from instance' do
    animal = Animal.new
    animal.ancestral_trait[:wild].should == :naturally
    animal.trait :wild => :depends
    animal.ancestral_trait[:wild].should == :depends
  end

  should 'set trait on subclass' do
    Cat.trait :sound => :meow
    Cat.trait[:sound].should == :meow
  end

  should 'not modify traits of other classes' do
    Animal.trait[:sound].should == nil
    Tiger.trait[:sound].should == nil
  end

  should 'get ancestral trait from class in superclass' do
    Cat.ancestral_trait[:wild].should == :naturally
  end

  should 'get ancestral trait from instance in superclass' do
    Cat.new.ancestral_trait[:wild].should == :naturally
  end
end
