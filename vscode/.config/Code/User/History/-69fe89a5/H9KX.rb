class CfSelectorComponent < ViewComponent::Base
  def initialize(params)
    super

    @id = params[:id] || 'cf-selector'
    @options = params[:options]
    @placeholder = params[:placeholder]
    @default_value = set_default_value(params)
    @default_name = @default_value ? @options.dig(@default_value, :name) : @placeholder
    @variable_name = params[:variable_name]
    @disabled = params[:disabled] || false
    @events = params[:events]
    @variable_class = params[:variable_class]
    @filter = params[:filter] || false
    @class = params[:class]
    @dropdown_class = params[:dropdown_class]
  end

  def set_default_value(params)
    if @placeholder.present?
      nil
    elsif params.keys.include?(:default_value)
      params[:default_value]
    else
      @options.keys.first
    end
  end

  def options
    hash = {
      id: "#{@id}-hidden-value"
    }
    hash.merge!(**@events) if @events.present?
    hash.merge!(class: @variable_class) if @variable_class.present?

    hash
  end

  def dropdown_attributes
    attributes = { 'aria-labelledby': "#{@id}-button", id: "#{@id}-dropdown-menu" }

    classes = [@dropdown_class].compact
    classes << 'pre-scrollable' if @filter
    datas = {}
    datas = { 'dropup-auto': 'false' } if @filter
    attributes.merge!(class: classes.join(' '), data: datas)
  end
end
