require File.expand_path('../../../helper', __FILE__)

describe 'Node::generate_mapping' do
  def gen(const)
    Innate::Node.generate_mapping(const)
  end

  should 'transform class names into snake_case locations' do
    gen(     'O').should == '/o'
    gen(    'Oo').should == '/oo'
    gen(   'Ooo').should == '/ooo'
    gen(  'OooO').should == '/oooo'
    gen( 'OooOo').should == '/ooo_oo'
    gen('OooOoo').should == '/ooo_ooo'
    gen('OOOooo').should == '/oooooo'
    gen('OooOOO').should == '/oooooo'
    gen('OoOoOo').should == '/oo_oo_oo'
  end

  should 'transform namespaces into leading parts of the location' do
    gen('O::O').should == '/o/o'
    gen('O::O::O').should == '/o/o/o'
    gen('O::O::O::O').should == '/o/o/o/o'
  end

  should 'transform leading parts just like standalone part' do
    gen(     'O::O').should == '/o/o'
    gen(    'Oo::O').should == '/oo/o'
    gen(   'Ooo::O').should == '/ooo/o'
    gen(  'OooO::O').should == '/oooo/o'
    gen( 'OooOo::O').should == '/ooo_oo/o'
    gen('OooOoo::O').should == '/ooo_ooo/o'
    gen('OOOooo::O').should == '/oooooo/o'
    gen('OooOOO::O').should == '/oooooo/o'
    gen('OoOoOo::O').should == '/oo_oo_oo/o'
  end
end
