class InputComponent < ViewComponent::Base
  attr_accessor :title

  def initialize(title)
    super

    @title = title
  end
end
