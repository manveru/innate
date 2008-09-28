require 'logger'

class Page
  C = Options.for(:wiki)
  GBLOB_CACHE = {}
  LOG_CACHE = {}

  begin
    G = Git.open(C.repo, :log => Logger.new($stdout))
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
    return nil unless rev
    ref = "#{rev}:#{repo_file}"
    GBLOB_CACHE[ref] ||= G.gblob(ref).contents + "\n"
  rescue Git::GitExecuteError => ex
    p :read => ex
    nil
  end

  def revisions
    object = "-- #{repo_file}"
    LOG_CACHE[object] ||= G.lib.log_commits(:object => object)
  rescue Git::GitExecuteError => ex
    p :revisions => ex
    []
  end

  def save(content, comment = "Update #@name")
    File.open(file, 'w+'){|i|
      i.puts content.gsub(/\r\n|\r/, "\n")
    }
    G.add(repo_file)
    message = G.commit(comment)
    @revision = message[/Created commit (\w+):/, 1]
  rescue Git::GitExecuteError => ex
    puts ex
    nil
  ensure
    GBLOB_CACHE.clear
    LOG_CACHE.clear
  end

  def move(to, comment = "Move #@name to #{to}")
    return unless exists?
    return if @name == to
    G.lib.mv(repo_file, repo_file(to))
    message = G.commit(comment)
    @revision = message[/Created commit (\w+):/, 1]
    @name = to
  rescue Git::GitExecuteError => ex
    puts "move(%p, %p)" % [to, comment]
    p ex
    nil
  end

  def render(string = content)
    self.class.render(string)
  end

  def file
    File.join(C.repo, repo_file)
  end

  def repo_file(name = @name)
    "#{name}.owl"
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
