require 'logger'
require 'vendor/git_extension'

class Page
  C = Options.for(:wiki)
  GBLOB_CACHE = {}
  LOG_CACHE = {}
  EXT = '.org'

  begin
    G = Git.open(C.repo, :log => Innate::Log)
  rescue ArgumentError
    FileUtils.mkdir_p(C.repo)
    Dir.chdir(C.repo){ Git.init('.') }
    retry
  end

  def self.[](name)
    new(name)
  end

  def self.language
    Innate::Current.session[:language] || C.default_language
  end

  def self.list(language)
    Dir["#{C.repo}/#{language}/**/*#{EXT}"].map{|path|
      path.gsub(C.repo, '').gsub(/#{language}\//, '').gsub(/#{EXT}$/, '')[1..-1]
    }
  end

  def self.list_render
    out = ["* List"] + list.map{|path| " * [[#{path}]]" }
    render(out * "\n")
  end

  def self.diff(sha, style)
    require 'uv'
    diff = G.diff(sha).patch
    Uv.parse(diff, output = 'xhtml', syntax_name = 'diff', line_numbers = false, render_style = style, headers = false)
  end

  def diff(sha, style)
    diff = G.gcommit(sha).diff(repo_file).patch
    Uv.parse(diff, output = 'xhtml', syntax_name = 'diff', line_numbers = false, render_style = style, headers = false)
  end

  def self.show(sha, file)
    G.gblob("#{sha}:#{file}").contents
  end

  def initialize(name, revision = nil)
    @name = name
    @org = nil
    @revision = revision || revisions.first
  end

  def read(rev = @revision)
#    return File.read(file)
    return nil unless rev
    ref = "#{rev}:#{repo_file}"
    GBLOB_CACHE[ref] ||= G.gblob(ref).contents + "\n"
  rescue Git::GitExecuteError => ex
    p :read => ex
    nil
  rescue Errno::ENOENT
    nil
  end

  def revisions
    object = "-- #{repo_file}"
    LOG_CACHE[object] = G.lib.log_commits(:object => object)
  rescue Git::GitExecuteError => ex
    p :revisions => ex
    []
  end

  # TODO: make sure this is threadsafe
  def save(content, comment = "Update #@name")
    FileUtils.mkdir_p(File.dirname(file))
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

  # TODO: make sure this is threadsafe
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

  def history
    G.lib.log_commits_follow(:object => repo_file).map do |rev|
      G.gcommit(rev)
    end
  end

  def render(string = content)
    self.class.render(string)
  end

  def to_html
    org.to_html
  end

  def to_toc
    org.to_toc
  end

  def org
    @org ||= Org::OrgMode.apply(content)
  end

  def file
    File.join(C.repo, repo_file)
  end

  def repo_file(name = @name)
    File.join *"#{language}/#{name}#{EXT}".split('/')
  end

  def language
    self.class.language
  end

  def content
    read || ''
  end

  def exists?
    File.file?(file)
  end
end
