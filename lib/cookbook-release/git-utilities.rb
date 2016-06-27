require 'semantic'
require 'semantic/core_ext'
require 'mixlib/shellout'
require 'highline/import'

module CookbookRelease
  class GitUtilities

    attr_accessor :no_prompt

    def initialize(options={})
      @tag_prefix = options[:tag_prefix] || ''
      @shellout_opts = {
        cwd: options[:cwd]
      }
    end

    def self.git?(dir)
      File.directory?(::File.join(dir, '.git'))
    end

    def reset_command(new_version)
      remote = choose_remote
      "git tag -d #{new_version} ; git push #{remote} :#{new_version}"
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
      last = tag.stdout.split('-').first
      unless last
        $stderr.puts "No last release found, defaulting to 0.1.0"
        last = '0.1.0'
      end
      last.to_version
    end

    # These string are used to split git commit summary
    # it just needs to be unlikely in a commit message
    MAGIC_SEP        = '@+-+@+-+@+-+@'
    MAGIC_COMMIT_SEP = '@===@===@===@'

    def compute_changelog(since)
      log_cmd = Mixlib::ShellOut.new("git log --pretty=\"tformat:%an <%ae>#{MAGIC_SEP}%s#{MAGIC_SEP}%h#{MAGIC_SEP}%b#{MAGIC_COMMIT_SEP}\" #{since}..HEAD", @shellout_opts)
      log_cmd.run_command
      log_cmd.error!
      log = log_cmd.stdout
      log.split(MAGIC_COMMIT_SEP).map do |entry|
        next if entry.chomp == ''
        author, subject, hash, body = entry.chomp.split(MAGIC_SEP)
        Commit.new({
          author: author,
          subject: subject,
          hash: hash,
          body: body
        })
      end.compact.reject { |commit| commit[:subject] =~ /^Merge branch (.*) into/i }
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
end
