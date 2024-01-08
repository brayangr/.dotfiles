module Debts
  class NotifySlowPayersService < StandardServiceObject
    include ApplicationHelper

    def post_initialize
      @community = params[:community]
    end

    def call
      notify_slow_payer_value = @community.get_setting_value('notify_slow_payer')

      return false if notify_slow_payer_value.zero?

      set_locale

      period_expense = @community.last_closed_period_expense
      expiration_offset = -1.minute
      expiration_date = period_expense.expiration_date + expiration_offset

      due_date = Time.now
      expired = false
      diff = (expiration_date.to_date - Date.today).to_i

      # 1 notify before and after due date
      # 2 notify before due date
      # 3 notify after due date
      properties = []
      if diff == @community.days_pre_due_date && [1, 2].include?(notify_slow_payer_value)
        due_date = Time.now + (@community.days_pre_due_date + 1).days
        properties = @community.properties.slow_payers(due_date, @community.amount_to_notify_slow_payers)
      elsif diff == - @community.days_post_due_date && [1, 3].include?(notify_slow_payer_value)
        properties = @community.properties.slow_payers(due_date, @community.amount_to_notify_slow_payers)
        expired = true
      end

      return false unless properties.any?

      properties_ids = properties.map(&:id).uniq

      # This is to prevent notification of already payed debts
      Debt
        .where(property_id: properties_ids).where('money_balance > ? AND priority_date < ?', 0, Time.now)
        .order(:priority_date)
        .each { |debt| debt.add_payments; debt.save }

      period_bills = period_expense.bills
      extras_hash = {
        custom_text_field: expired ? 'email_text_post_due_date' : 'email_text_pre_due_date',
        diff_days: diff,
        expiration_date: I18n.l(expiration_date, format: :just_date_hyphen),
        period_expense_period: I18n.l(period_expense.period, format: :month_year),
        urls: {
          login: Rails.application.routes.url_helpers.log_in_url(host: ActionMailer::Base.default_url_options[:host]),
          home:  Rails.application.routes.url_helpers.part_owner_property_url(host: ActionMailer::Base.default_url_options[:host])
        }
      }

      users_to_notify(properties_ids).each do |user|
        user_properties = user.properties
        user_properties_ids = user_properties.map(&:id)
        bills = period_bills.where(property_id: user_properties_ids)
        paid_debt = 0
        owed_money = 0

        bills.each do |bill|
          paid_debt += bill.payment_amount
          owed_money += bill.price > bill.payment_amount ? (bill.price - bill.payment_amount) : 0
        end

        attach_bill = paid_debt.zero?
        extras_hash[:paid_amount] = to_currency(amount: paid_debt)
        extras_hash[:owed_amount] = to_currency(amount: owed_money)

        user_properties.each do |property|
          bill = period_bills.detect { |b| b.property_id == property.id }
          encrypted_bill = encrypt_text(bill.get_billable_id)
          url = SmartLinks::OnlinePayments.call(community: @community, encrypted_bill: encrypted_bill, user: user)

          extras_hash[:urls][:easy_pay] = url if @community.online_payment_activated?

          property_extras = {
            id: property.id,
            name: property.name,
            price: to_currency(amount: bill.price - (bill.payment_amount || 0)),
            payment_amount: to_currency(amount: bill.payment_amount),
            payment_found: bill.payment_amount.positive?,
            code: property.alphanumeric_code
          }

          byebug
          NotifyUserWithPdfJob.perform_later(
            _community_id:   @community.id,
            recipient:       user,
            community:       @community,
            origin_mail:     @community.contact_email,
            file_name:       attach_bill ? bill&.bill&.filename : nil,
            object:          attach_bill ? bill : nil,
            template:        'notify_slow_payers',
            extras:          extras_hash,
            property_extras: property_extras,
            _message:        I18n.t('jobs.notify_user_with_pdf_as_attachment')
          )
        end
      end
    end

    private

    def set_locale
      I18n.locale = @community.get_locale
    end

    def users_to_notify(properties_ids)
      User
        .with_valid_email
        .joins(:properties)
        .where(properties: { id: properties_ids })
        .eager_load(:properties)
    end
  end
end
