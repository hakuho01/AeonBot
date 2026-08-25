require 'singleton'

class Component include Singleton
  def initialize
    @initilized = false
  end

  def init(*args)
    unless @initilized
      @initilized = true
      construct(*args)
    end
    return self
  end

  protected

  def construct(*args)
  end
end