class InputComponent < ViewComponent::Base
  attr_accessor :title, :value, :id, :type, :name

  def initialize(title:, value:, id:, type:, name:)
    super

    @title = title
    @value = value
    @id = id
    @type = type
    @name = name
  end
end
