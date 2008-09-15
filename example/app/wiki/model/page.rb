require 'logger'

class Page
  C = Options.for(:wiki)

  begin
    G = Git.open(C.repo) #, :log => Logger.new($stdout))
  rescue ArgumentError
    FileUtils.mkdir_p(C.repo)
    Dir.chdir(C.repo){ Git.init('.') }
    retry
  end

  def self.[](name)
    new(name)
  end

  def initialize(name, revision = nil)
    @name = name
    @revision = revision || revisions.first
  end

  def read(rev = @revision)
    G.gblob("#{rev}:#{repo_file}").contents
  rescue Git::GitExecuteError => ex
    p :read => ex
    nil
  end

  def revisions
    G.lib.log_commits(:object => repo_file)
  rescue Git::GitExecuteError => ex
    p :revisions => ex
    []
  end

  def save(content, comment = "Update #@name")
    File.open(file, 'w+'){|i| i.write content.gsub(/\r\n|\r/, "\n") }
    G.add(repo_file)
    message = G.commit(comment)
    @revision = message[/Created commit (\w+):/, 1]
  rescue Git::GitExecuteError => ex
    puts ex
    nil
  end

  def render(string = content)
    self.class.render(string)
  end

  def file
    File.join(C.repo, repo_file)
  end

  def repo_file
    "#@name.owl"
  end

  def content
    read || ''
  end

  def exists?
    File.file?(file)
  end

  def self.render(string)
    owl = OWLScribble.new(string)
    owl.to_html
  end

  def self.list
    files = Dir["#{C.repo}/*.owl"].map{|f| File.basename(f, '.owl') }
    out = files.map{|f| " * [[#{f}]]" }
    render ["= List =", *out].join("\n")
  end
end
