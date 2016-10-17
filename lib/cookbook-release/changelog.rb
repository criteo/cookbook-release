module CookbookRelease
  class Changelog

    DEFAULT_OPTS = {
      expand_major: true,
      expand_risky: true,
    }

    def initialize(git, opts = {})
      @git = git
      @opts = DEFAULT_OPTS.merge(opts)
    end

    def raw
      changelog.map(&:to_s_oneline)
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

    def markdown
      result = []
      result << changelog.map do |c|
        full_body ||= @opts[:expand_major] && c.major?
        full_body ||= @opts[:expand_risky] && c.risky?
        full_body ||= @opts[:expand_commit] && (c[:subject] =~ @opts[:expand_commit] || c[:body] =~ @opts[:expand_commit])
        c.to_s_markdown(full_body)
      end
      result.join("\n")
    end

    private

    def changelog
      ref = ENV['RELEASE_BRANCH'] || 'origin/master'
      @git.compute_changelog(ref)
    end
  end
end
