# frozen_string_literal: true

# Notify user or employee
module Jobs
  # receives: different param by case
  class NotifyUserWithPdfJob < LibJob
    def perform
      return send_with_sendgrid_api if sendgrid_template == 'notify_user_with_pdf_payment'

      byebug
      params_helper =
        if event['template'] == 'notify_slow_payers'
          MailerJobsHelpers::NotifySlowPayerHelper.new(event)
        else
          MailerJobsHelpers::NotifyUserWithPdfHelper.new(event)
        end
      mail = UserMailer.notify_bill(params_helper: params_helper)
      MailDeliver.safe_deliver_mail(mail)
      update_payment if event['origin_type'] == 'Payment'
    end

    def send_with_sendgrid_api
      SendgridMailer.send_email(self, params_helper: MailerJobsHelpers::NotifyUserWithPdfPaymentHelper)

      update_payment
    end

    def sendgrid_template
      event.dig('extras', 'sendgrid_template')
    end

    def update_payment
      Payment.update(event['origin_id'], notifying: false)
    end
  end
end
