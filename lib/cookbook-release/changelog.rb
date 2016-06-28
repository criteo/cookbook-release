module CookbookRelease
  class Changelog
    def initialize(git)
      @git = git
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
        full_body = c.risky? || c.major?
        c.to_s_html(full_body)
      end.map { |c| "    <p>#{c}</p>" }
      result <<  <<-EOH
  </body>
</html>
      EOH
      result.join("\n")
    end

    private

    def changelog
      @git.compute_changelog('master')
    end

  end
end
