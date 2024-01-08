class InputComponent < ViewComponent::Base
  attr_accessor :title, :value, :id, :type, :name, :options

  def initialize(title:, value:, id:, type:, name:, options:)
    super

    @title = title
    @value = value
    @id = id
    @type = type
    @name = name
    @options = options
  end
end
