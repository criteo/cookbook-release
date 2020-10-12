module CookbookRelease
  class Changelog

    DEFAULT_OPTS = {
      expand_major: true,
      expand_risky: true,
      separate_nodes: true,
      short_sha: true
    }

    RISKY = 'RISKY/BREAKING (details below):'
    NO_RISKY = 'NO RISKY/BREAKING COMMITS. READ FULL CHANGELOG.'
    NON_NODES_ONLY = 'Non-risky/major, Non-node-only commits'
    NODES_ONLY = 'Commits impacting only nodes'
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
      if risky_commits.any?
        result << "#{RISKY}\n" << risky_commits.map(&:to_s_oneline).join("\n") << "\n"
      else
        result << "#{NO_RISKY}\n\n"
      end
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
        full_body ||= @opts[:separate_nodes] && c.nodes_only?
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
      if risky_commits.any?
        result << "    <p>#{RISKY}</p>\n" << risky_commits.map { |c| c.to_s_html(false) }.map {|c| "    <p>#{c}</p>"}.join("\n")
      else
        result << "    <p>#{NO_RISKY}</p>\n\n"
      end
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
        full_body ||= @opts[:separate_nodes] && c.nodes_only?
        full_body ||= @opts[:expand_commit] && (c[:subject] =~ @opts[:expand_commit] || c[:body] =~ @opts[:expand_commit])
        full_body ||= @opts[:expand_commit] && (c[:subject] =~ @opts[:expand_commit] || c[:body] =~ @opts[:expand_commit])
        c.to_s_markdown(full_body)
      end.join("\n")
    end

    def markdown_priority
      risky_commits = changelog.select { |c| c.risky? || c.major? }
      result = []
      if risky_commits.any?
        result << "*#{RISKY}*\n" << risky_commits.map { |c| c.to_s_markdown(false) }.join("\n") << "\n"
      else
        result << "*#{NO_RISKY}*\n\n"
      end
      result << "*#{FULL}*\n"
      result << changelog.map { |c| c.to_s_markdown(false) }.join("\n")
      if risky_commits.any?
        result << "\n#{DETAILS}\n"
        result << risky_commits.map { |c| c.to_s_markdown(true) }.join("\n")
      end
      result
    end

    def markdown_priority_nodes
      result = []
      result << append_risky(changelog)
      result << append_by_impact(changelog)
      result << append_risky_details(changelog)
      result
    end

    private

    # @param changelog [Array<Commit>]
    # @return [String] a string describing the changelog
    def append_by_impact(changelog)
      not_nodes_only_commits = changelog.reject { |c| c.nodes_only? || c.risky? || c.major? }
      nodes_only_commits = changelog.select(&:nodes_only?)
      output = []
      if not_nodes_only_commits.any?
        txt = not_nodes_only_commits.map { |c| c.to_s_markdown(false) }.join("\n")
        output << "*#{NON_NODES_ONLY}*\n#{txt}\n"
      end
      if nodes_only_commits.any?
        txt = nodes_only_commits.map { |c| c.to_s_markdown(false) }.join("\n")
        output << "*#{NODES_ONLY}*\n#{txt}\n"
      end
      output.join
    end

    # @param changelog [Array<Commit>]
    # @return [String] a string describing the changelog
    def append_risky_details(changelog)
      risky_commits = changelog.select { |c| c.risky? || c.major? }
      if risky_commits.any?
        "\n#{DETAILS}\n" + risky_commits.map { |c| c.to_s_markdown(true) }.join("\n")
      else
        ''
      end
    end

    # @param changelog [Array<Commit>]
    # @return [String] a string describing the changelog
    def append_risky(changelog)
      risky_commits = changelog.select { |c| c.risky? || c.major? }
      if risky_commits.any?
        "*#{RISKY}*\n" << risky_commits.map { |c| c.to_s_markdown(false) }.join("\n") << "\n"
      else
        "*#{NO_RISKY}*\n\n"
      end
    end

    def changelog
      ref = ENV['RELEASE_BRANCH'] || 'origin/master'
      @git.compute_changelog(ref, @opts[:short_sha])
    end
  end
end
