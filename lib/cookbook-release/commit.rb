require 'forwardable'
require 'unicode/emoji'

module CookbookRelease
  class Commit
    extend Forwardable
    def_delegators :@hash, :[]

    def initialize(hash)
      @hash = hash
    end

    def major?
      [
        /breaking/i,
        /\[major\]/i
      ].any? do |r|
        self[:subject] =~ r
      end
    end

    def patch?
      [
        /\bfix\b/i,
        /\bbugfix\b/i,
        /\[patch\]/i
      ].any? do |r|
        self[:subject] =~ r
      end
    end

    def minor?
      !(major? || patch?)
    end

    def risky?
      !!(self[:subject] =~ /\[risky\]/i)
    end

    def nodes_only?
      self[:nodes_only]
    end

    def color
      case true
      when major?
        :red
      when risky?
        :red
      else
        :grey
      end
    end

    def to_s_oneline
      "#{self[:hash]} #{self[:author]} <#{self[:email]}> #{self[:subject]}"
    end

    def to_s_html(full)
      result = []
      result << <<-EOH
<font color=#{color.to_s}>
  #{self[:hash]} #{self[:author]} <#{self[:email]}> #{self[:subject]}
</font>
      EOH
      if full && self[:body]
        result << <<-EOH
<pre>
#{strip_change_id(self[:body])}
</pre>
        EOH
      end

      result.join("\n")
    end

    def to_s_markdown(full)
      result = "*#{self[:hash]}* "
      if self[:subject] =~ /risky|breaking/i
        slack_user = self[:email].split('@')[0]
        result << "@#{slack_user}"
      else
        result << "_#{self[:author]} <#{self[:email]}>_"
      end
      result << ' '
      result << backtick_string(self[:subject])
      result << "\n```\n#{strip_change_id(self[:body])}```" if full && self[:body]
      result
    end

    def backtick_string(input)
      s = input.gsub(/( )?(#{Unicode::Emoji::REGEX})( )?/, '` \2 `')
               .gsub(/( )?``( )?/, '')
      s += '`' unless s =~ /`$/
      s = '`' + s unless s =~ /^`/
      s
    end

    private

    def strip_change_id(body)
      body.each_line.reject {|l| l.start_with?('Change-Id') }.join
    end
  end
end
