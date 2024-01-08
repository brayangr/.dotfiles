class InputComponentPreview < ViewComponent::Preview
  def default
    params = {
      icon_class: 'fa fa-info-circle',
      type: 'number',
      title: "Tooltip text",
      value: 0,
      id: "input-id",
      name: 'field_name',
      options: { min: 0 }
    }

    render(InputComponent.new(**params))
  end
end
