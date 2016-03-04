class Release

  def self.current_version
    r = Release.new(GitUtilities.new)
    begin
      r.new_version.first
    rescue ExistingRelease
      r.last_release
    end
  end

  class ExistingRelease < StandardError
  end

  attr_reader :git

  def initialize(git, opts={})
    @git         = git
    @no_prompt   = opts[:no_prompt]
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
      puts "* #{commit[:hash]} #{commit[:subject]} (#{commit[:author]})"
    end
  end

  def display_changelog(new_version)
    puts "Changelog for #{new_version}:"
    git_changelog.each do |commit|
      puts "* #{commit[:hash]} #{HighLine.color(commit[:subject], commit.color)} (#{commit[:author]})"
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
    new_version = prepare_release
    begin
      git.tag(new_version)
      display_changelog(new_version)
      puts ""
      agreed = @no_prompt || agree("Do you agree with this changelog?") { |q| q.default = "yes" }
      exit 1 unless agreed
      git.push_tag(new_version)
      supermarket = Supermarket.new
      supermarket.publish_ck(@category)
    rescue
      puts HighLine.color("Release aborted, you have to reset to previous state manually", :red)
      puts ":use with care: #{git.reset_command(new_version)}"
      raise
    end
  end
end
