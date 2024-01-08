class DateSelectorComponent < ViewComponent::Base
  def initialize(**params)
    super

    @id = params[:id] || 'date'
    @optional = params[:optional] || false
    @default_value = if params[:default_value].present?
                       params[:default_value].to_date
                     elsif !@optional
                       Date.today
                     end
    @calendar_date = @optional ? Date.today : @default_value
    @variable_name = params[:variable_name] || 'date'
    @disabled = params[:disabled] || false
    @date_grid = prepare_calendar_grid
    @class = params[:class]
    @tooltip = params[:tooltip] || false
    @data = params[:data] || {}
    @placeholder = params[:placeholder] || false
  end

  def prepare_calendar_grid
    start_date = @calendar_date.beginning_of_month
    end_date = @calendar_date.end_of_month
    days_of_month = end_date.day
    start_week_day = start_date.wday
    end_week_day = end_date.wday
    previous_days = start_week_day.zero? ? 6 : start_week_day - 1
    post_days = end_week_day.zero? ? -1 : 6 - end_week_day

    (- previous_days..days_of_month + post_days).map do |day|
      date = start_date + day.days
      { day: date.day, month: date.month, year: date.year, current_month: date.month == @calendar_date.month, selected: same_date(@calendar_date, date), date: date }
    end
  end

  def same_date(date_1, date_2)
    date_1.day == date_2.day && date_1.month == date_2.month && date_1.year == date_2.year
  end

  def dropdown_item_class(date_hash)
    class_array = []
    class_array << 'selected' if date_hash[:selected]
    class_array << (date_hash[:current_month] ? 'date-of-the-month' : 'date-of-another-month')
    class_array << 'today' if same_date(Date.today, date_hash[:date])

    class_array.join(' ')
  end
end
