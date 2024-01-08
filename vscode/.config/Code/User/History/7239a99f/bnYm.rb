module SortableColumnComponentHelper
  def sort_property_payments_params(sortable)
    path_params = { property_id: @property.id, current_tab: @current_tab, order_by: sortable, order_option: @order_option }
    { title: Payment.human_attribute_name(sortable), path: async_no_period_property_payments_path(path_params), direction: order_params(sortable, @order_option) }
  end

  def sort_salary_payment_drafts_params(title)
    next_order = @order == 'desc' ? 'asc' : 'desc'
    {
      title: title,
      path: async_remunerations_salary_payment_drafts_path(order: next_order, month: @month, year: @year, employee_finder: @employee_finder, tab: @tab),
      direction: @order
    }
  end

  def order_params(sortable, direction)
    @order_by.to_s == sortable.to_s ? direction : ''
  end
end
