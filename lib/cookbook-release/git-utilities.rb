require 'semantic'
require 'semantic/core_ext'
require 'mixlib/shellout'
require 'highline/import'

class GitUtilities

  attr_accessor :no_prompt

  def initialize(options={})
    @tag_prefix = options[:tag_prefix] || ''
    @shellout_opts = {
      cwd: options[:cwd]
    }
  end

  def self.git?(dir)
    !Mixlib::ShellOut.new('git status', cwd: dir).run_command.error?
  end

  def reset_command(new_version)
    "git reset --hard HEAD^ && git tag -d #{new_version}"
  end

  def clean_index?
    clean_index = Mixlib::ShellOut.new("git diff --exit-code", @shellout_opts)
    clean_index.run_command
    clean_staged = Mixlib::ShellOut.new("git diff --exit-code --cached", @shellout_opts)
    clean_staged.run_command
    !clean_index.error? && !clean_staged.error?
  end

  def clean_index!
    raise "All changes must be committed!" unless clean_index?
  end

  def compute_last_release

    tag = Mixlib::ShellOut.new([
      'git describe',
      "--tags",
      "--match \"#{@tag_prefix}[0-9]\.[0-9]*\.[0-9]*\""
    ].join(" "), @shellout_opts)
    tag.run_command
    tag.stdout.split('-').first.to_version
  end

  # This string is used to split one-line git commit summary
  # it just needs to be unlikely in a commit message
  MAGIC_SEP = '@+-+@+-+@+-+@'

  def compute_changelog(since)
    # TODO use whole commit message instead of title only
    log_cmd = Mixlib::ShellOut.new("git log --pretty='format:%an <%ae>#{MAGIC_SEP}%s#{MAGIC_SEP}%h' #{since}..HEAD", @shellout_opts)
    log_cmd.run_command
    log = log_cmd.stdout
    log.split("\n").map do |entry|
      author, subject, hash = entry.chomp.split(MAGIC_SEP)
      Commit.new({
        author: author,
        subject: subject,
        hash: hash
      })
    end.reject { |commit| commit[:subject] =~ /^Merge branch (.*) into/i }
  end

  def tag(version)
    cmd = Mixlib::ShellOut.new("git tag #{@tag_prefix}#{version}", @shellout_opts)
    cmd.run_command
    cmd.error!
  end

  def choose_remote
    cmd = Mixlib::ShellOut.new("git remote", @shellout_opts)
    cmd.run_command
    cmd.error!
    remotes = cmd.stdout.split("\n")
    if remotes.size == 1 || @no_prompt
      puts "Choosing remote #{remotes.first}" if @no_prompt
      remotes.first
    else
      choose(*remotes)
    end
  end

  def push_tag(version)
    remote = choose_remote
    cmd = Mixlib::ShellOut.new("git push #{remote} #{@tag_prefix}#{version}", @shellout_opts)
    cmd.run_command
    cmd.error!
  end
end
