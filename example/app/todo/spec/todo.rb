require 'innate/spec'

FileUtils.rm_f('todo.pstore')

require 'start'
require 'hpricot'

describe Todo do
  behaves_like :mock, :multipart

  it 'starts out without tasks' do
    doc = Hpricot(get('/').body)
    doc.at(:table).inner_text.strip.should.be.empty
  end

  it 'adds a task and redirects back' do
    got = post('/create', multipart('title' => 'first task'))
    got.status.should == 302
    got['Location'].should == 'http://example.org/'
  end

  it 'shows the task as pending' do
    doc = Hpricot(get('/').body)
    doc.at('td/input[@name=title]')['value'].should == 'first task'
    doc.at('td/input[@name=done]')['checked'].should.be.nil
  end

  it 'updates the task title and redirects back' do
    got = post('/update', multipart('id' => 'first task', 'title' => 'wash dishes'))
    got.status.should == 302
    got['Location'].should == 'http://example.org/'
  end

  it 'shows the changed task title' do
    doc = Hpricot(get('/').body)
    doc.at('td/input[@name=title]')['value'].should == 'wash dishes'
    doc.at('td/input[@name=done]')['checked'].should.be.nil
  end

  it 'marks the task as done and redirects back' do
    mp = multipart('id' => 'wash dishes', 'title' => 'wash dishes', 'done' => 'on')
    got = post('/update', mp)
    got.status.should == 302
    got['Location'].should == 'http://example.org/'
  end

  it 'shows the task as done' do
    doc = Hpricot(get('/').body)
    doc.at('td/input[@name=title]')['value'].should == 'wash dishes'
    doc.at('td/input[@name=done]')['checked'].should == 'checked'
  end

  it 'deletes the task and redirects back' do
    got = post('/delete', multipart('id' => 'wash dishes'))
    got.status.should == 302
    got['Location'].should == 'http://example.org/'
  end

  it 'shows no tasks' do
    doc = Hpricot(get('/').body)
    doc.at(:table).inner_text.strip.should.be.empty
  end
end
