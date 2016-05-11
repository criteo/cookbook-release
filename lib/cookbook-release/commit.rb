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

    def color
      case true
      when major?
        :red
      else
        :grey
      end
    end

  end
end
