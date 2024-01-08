class InputComponent < ViewComponent::Base
  attr_accessor :title, :value, :id, :type, :name, :options

  def initialize(params)
    super

    @title = params[:title]
    @value = params[:value]
    @id = params[:id]
    @type = params[:type]
    @name = params[:name]
    @options = params[:options]
    @icon_class = params[:icon_class]
  end
end
