class Commit
  extend Forwardable
  def_delegators :@hash, :[]

  def initialize(hash)
    @hash = hash
  end

  def major?
    !!(self[:subject] =~ /breaking/i)
  end

  def patch?
    !!(self[:subject] =~ /\bfix\b/i) || !!(self[:subject] =~ /\bbugfix\b/i)
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
