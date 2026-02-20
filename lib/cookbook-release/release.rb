require 'highline/import'
require_relative 'git-utilities'
require_relative 'supermarket'

module CookbookRelease
  class Release

    # file will be used to determine the git directory
    def self.current_version(file)
      dir = File.dirname(file)
      version_file = File.join(dir, '.cookbook_version')
      git_root = GitUtilities.find_root(dir)

      if !GitUtilities.git?(dir) && git_root.nil?
        return File.read(version_file) if File.exist?(version_file)
        raise "Can't determine version in a non-git environment without #{version_file}"
      end

      git = if git_root == dir
              GitUtilities.new(cwd: dir)
            else
              GitUtilities.new(cwd: git_root, tag_prefix: "#{File.basename(dir)}-", sub_dir: dir)
            end

      r = Release.new(git)
      begin
        r.new_version.first
      rescue ExistingRelease
        r.last_release
      end.tap { |v| File.write(version_file, v) }
    end

    class ExistingRelease < StandardError
    end

    attr_reader :git

    def initialize(git, opts={})
      @git         = git
      @no_prompt   = opts[:no_prompt]
      @skip_upload   = opts[:skip_upload]
      @git.no_prompt = @no_prompt
      @category    = opts[:category] || 'Other'
    end

    def last_release
      @last_release ||= git.compute_last_release
    end

    def git_changelog
      @git_changelog ||= git.compute_changelog(last_release)
    end

    # return the new version and the reasons
    def new_version
      return ['0.1.0'.to_version, []] unless git.has_any_release?
      %w(major minor patch).each do |level|
        changes = git_changelog.select(&"#{level}?".to_sym)
        return [ last_release.send("#{level}!"), changes ] if changes.size > 0
      end
      raise ExistingRelease, "No commit since last release (#{last_release})"
    end

    def user_defined_version
      puts "Which kind of upgrade ?"
      new_release_level = choose(*%w(major minor patch))
      last_release.send("#{new_release_level}!")
    end

    def display_suggested_version(new_version, reasons)
      puts "Suggested version: " + new_version.to_s
      puts "Commits that suggest this change:"
      reasons.each do |commit|
        puts "* #{commit[:hash]} #{commit[:subject]} (#{commit[:author]} <#{commit[:email]}>)"
      end
    end

    def display_changelog(new_version)
      puts "Changelog for #{new_version}:"
      git_changelog.each do |commit|
        puts "* #{commit[:hash]} #{HighLine.color(commit[:subject], commit.color)} (#{commit[:author]} <#{commit[:email]}>)"
      end
    end

    def prepare_release
      git.clean_index!
      new_version , reasons = self.new_version
      puts "Last release was:  " + last_release.to_s
      display_suggested_version(new_version, reasons)
      puts ""

      agreed = @no_prompt || agree("Do you agree with that version?") { |q| q.default = "yes" }
      new_version = user_defined_version unless agreed
      puts "New release will be #{new_version}"
      puts ""

      new_version
    end

    def release!

      new_version = begin
                      prepare_release
                    rescue ExistingRelease
                      raise unless ENV['COOKBOOK_RELEASE_SILENT_FAIL']
                      exit 0
                    end
      begin
        git.tag(new_version)
        display_changelog(new_version)
        puts ""
        agreed = @no_prompt || agree("Do you agree with this changelog?") { |q| q.default = "yes" }
        exit 1 unless agreed
        git.push_tag(new_version)
        supermarket = Supermarket.new
        supermarket.publish_ck(@category, git.sub_dir) unless @skip_upload
      rescue
        puts HighLine.color("Release aborted, you have to reset to previous state manually", :red)
        puts ":use with care: #{git.reset_command(new_version)}"
        raise
      end
    end
  end
end

# For simplicity of use
Release = CookbookRelease::Release
