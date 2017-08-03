module CookbookRelease
  class Changelog

    DEFAULT_OPTS = {
      expand_major: true,
      expand_risky: true,
      short_sha: true
    }

    RISKY = 'Risky/Breaking (details below):'
    FULL = 'Full changelog:'
    DETAILS = 'Details of risky commits:'

    def initialize(git, opts = {})
      @git = git
      @opts = DEFAULT_OPTS.merge(opts)
    end

    def raw
      changelog.map(&:to_s_oneline)
    end

    def raw_priority
      risky_commits = changelog.select { |c| c.risky? || c.major? }
      result = []
      result << "#{RISKY}\n" << risky_commits.map(&:to_s_oneline).join("\n") << "\n" if risky_commits.any?
      result << "#{FULL}\n"
      result << changelog.map(&:to_s_oneline).join("\n")
    end

    def html
      result = []
      result << <<-EOH
<html>
  <body>
      EOH
      result << changelog.map do |c|
        full_body ||= @opts[:expand_major] && c.major?
        full_body ||= @opts[:expand_risky] && c.risky?
        full_body ||= @opts[:expand_commit] && (c[:subject] =~ @opts[:expand_commit] || c[:body] =~ @opts[:expand_commit])
        c.to_s_html(full_body)
      end.map { |c| "    <p>#{c}</p>" }
      result <<  <<-EOH
  </body>
</html>
      EOH
      result.join("\n")
    end

    def html_priority
      risky_commits = changelog.select { |c| c.risky? || c.major? }
      result = []
      result << <<-EOH
<html>
  <body>
      EOH
      result << "    <p>#{RISKY}</p>\n" << risky_commits.map { |c| c.to_s_html(false) }.map {|c| "    <p>#{c}</p>"}.join("\n") if risky_commits.any?
      result << "    <p>#{FULL}</p>\n"
      result << changelog.map { |c| c.to_s_html(false) }.map { |c| "    <p>#{c}</p>" }.join("\n")
      if risky_commits.any?
        result << "\n<p>#{DETAILS}</p>\n"
        result << risky_commits.map { |c| c.to_s_html(true) }.map { |c| "    <p>#{c}</p>" }.join("\n")
      end
      result <<  <<-EOH
  </body>
</html>
      EOH
      result.join("\n")
    end

    def markdown
      changelog.map do |c|
        full_body ||= @opts[:expand_major] && c.major?
        full_body ||= @opts[:expand_risky] && c.risky?
        full_body ||= @opts[:expand_commit] && (c[:subject] =~ @opts[:expand_commit] || c[:body] =~ @opts[:expand_commit])
        c.to_s_markdown(full_body)
      end.join("\n")
    end

    def markdown_priority
      risky_commits = changelog.select { |c| c.risky? || c.major? }
      result = []
      result << "*#{RISKY}*\n" << risky_commits.map { |c| c.to_s_markdown(false) }.join("\n") << "\n" if risky_commits.any?
      result << "*#{FULL}*\n"
      result << changelog.map { |c| c.to_s_markdown(false) }.join("\n")
      if risky_commits.any?
        result << "\n#{DETAILS}\n"
        result << risky_commits.map { |c| c.to_s_markdown(true) }.join("\n")
      end
      result
    end

    private

    def changelog
      ref = ENV['RELEASE_BRANCH'] || 'origin/master'
      @git.compute_changelog(ref, @opts[:short_sha])
    end
  end
end
