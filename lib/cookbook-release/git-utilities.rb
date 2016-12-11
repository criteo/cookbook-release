require 'semantic'
require 'semantic/core_ext'
require 'mixlib/shellout'
require 'highline/import'
require 'git'

module CookbookRelease
  class GitUtilities

    attr_accessor :no_prompt

    def initialize(options={})
      @tag_prefix = options[:tag_prefix] || ''
      cwd = options[:cwd] || Dir.pwd
      @shellout_opts = {
        cwd: cwd
      }
      @g = Git.open(cwd)
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

    def _compute_last_release
      tag = Mixlib::ShellOut.new([
        'git describe',
        "--tags",
        "--match \"#{@tag_prefix}[0-9]\.[0-9]*\.[0-9]*\""
      ].join(" "), @shellout_opts)
      tag.run_command
      tag.stdout.split('-').first
    end

    def has_any_release?
      !!_compute_last_release
    end

    def compute_last_release
      last = _compute_last_release
      unless last
        $stderr.puts "No last release found, defaulting to 0.1.0"
        last = '0.1.0'
      end
      last.to_version
    end

    def compute_changelog(since, short_sha = true)
      @g.log.between(since, 'HEAD').map do |commit|
        message = commit.message.lines.map(&:chomp).compact.delete_if(&:empty?)
        Commit.new(
          author: commit.author.name,
          subject: message.delete_at(0),
          hash: short_sha ? commit.sha[0,7] : commit.sha,
          body: message.empty? ? nil : message.join("\n"),
          is_merge_commit: commit.parents.length > 1
        )
      end.reject { |commit| commit[:is_merge_commit] }
    end

    def tag(version)
      @g.add_tag("#{@tag_prefix}#{version}")
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
