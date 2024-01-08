class InputComponent < ViewComponent::Base
  attr_accessor :title

  def initialize(title:, value:, id:, type: name:)
    super

    @title = title
  end
end
