# frozen_string_literal: true

module MailerJobsHelpers
  class NotifySlowPayerHelper < BaseJobHelper
    include OriginInfo
    include FileInfo

    INSTANCE_VARIABLES = %i[
      mail_info recipient_info template_info file_info community_info origin_info content_info property_info
    ].freeze

    def mail_info
      {
        mail_type:   OutgoingMail.mail_types[includes_attachment? ? :send_with_attachment : :notify_user_without_attachment],
        origin_mail: @event['origin_mail'],
        subject:     payment_dependant_subject
      }
    end

    def community_info
      {
        community:     community,
        contact_phone: community.contact_phone
      }
    end

    def content_info
      {
        custom_text_field:     custom_text_field,
        diff_days:             diff_days,
        expiration_date:       extras['expiration_date'],
        expired:               expired_key == 'post',
        has_file:              includes_attachment?,
        owed_amount:           extras['owed_amount'],
        paid_amount:           extras['paid_amount'],
        period_expense_period: extras['period_expense_period'],
        urls:                  extras['urls']
      }
    end

    def recipient_info
      {
        email_to:             @event['email_to'],
        recipient_first_name: @event['recipient_first_name'],
        recipient_id:         @event['recipient_id'],
        recipient_name:       @event['recipient_name'],
        recipient_type:       @event['recipient_type']
      }
    end

    def template_info
      {
        template_path: 'user_mailer',
        template_name: @event['template']
      }
    end

    def property_info
      {
        property_id:                  property_extras['id'],
        property_name:                property_extras['name'],
        property_bill_price:          property_extras['price'],
        property_bill_payment_amount: property_extras['payment_amount'],
        property_bill_payment_found:  property_extras['payment_found'],
        property_code:                property_extras['code']
      }
    end

    def community
      @community ||= Community.find_by(id: @event['community_id'])
    end

    def custom_text_field
      byebug
      community[extras['custom_text_field']].gsub('{usuario}', @event['recipient_name'])
                                            .gsub('{días}', community.days_pre_due_date.to_s)
                                            .gsub('{d&iacute;as}', community.days_pre_due_date.to_s)
                                            .gsub('{monto_adeudado}', property_extras['price'])
                                            .gsub('{monto_pagado}', property_extras['payment_amount'])
                                            .html_safe
    end

    def diff_days
      [extras['diff_days'], I18n.t('mailers.shared.day').pluralize(extras['diff_days'])].join(' ')
    end

    def extras
      @event['extras']
    end

    def property_extras
      @event['property_extras'].present? ? @event['property_extras'] : {}
    end

    def includes_attachment?
      @event['origin_id'].present?
    end

    def expired_key
      extras['custom_text_field'].gsub('email_text_', '').gsub('_due_date', '')
    end

    def payment_dependant_subject
      paid_key = includes_attachment? ? 'fully_unpaid' : 'partially_paid'
      I18n.t("mailers.notify_bill.slow_payer.subject_#{paid_key}_#{expired_key}",
             community_name: community.name, property_name: property_info[:property_name])
    end
  end
end
