require 'sendgrid-ruby'

class SendgridMailer
  EMAIL_SUPPORT = 'soporte@comunidadfeliz.com'.freeze # cf_to_admin emails

  class << self
    include SendGrid

    def send_email(job, params_helper:, extras: nil)
      job.event.merge!(extras) if extras.present?

      email_params = params_helper.new(job.event)
      outgoing_mail = job.save_outgoing_mail(email_params.outgoing_mail)
      sendgrid_mail = build_email(email_params, mail_id: outgoing_mail.id)

      email_params.mail_info[:files]&.each do |file|
        sendgrid_mail.add_attachment(build_attachment(file))
      end

      begin
        response = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
                                .client.mail._('send')
                                .post(request_body: sendgrid_mail.to_json)
      rescue StandardError => e
        puts e.message
        pp e.backtrace
      end
      byebug
      puts "Email ##{outgoing_mail.id} [#{email_params.base[:template_name]}] sent (response status_code: #{response.status_code})"
      # TODO: handle non 20X status_code response
    end

    def build_email(params, mail_id:)
      # TODO: raise exception if base key is not sent
      personalization = Personalization.new
      personalization.add_to(Email.new(email: params.base[:email_to]))
      personalization.add_dynamic_template_data(params.sendgrid_dynamic_data)

      personalization = add_cc_and_bcc(params_cc_bcc: params.cc_bcc_recipient, personalization: personalization) if params.cc_bcc_recipient.present?

      Mail.new.tap do |mail|
        mail.template_id = template_id_for(params.base[:template_name])
        mail.from = Email.new(email: params.base[:email_from])
        mail.reply_to = Email.new(email: params.reply_to) if params.reply_to.present?
        mail.subject = params.base[:subject]
        # replacement of 'X-SMTPAPI' header used on UserMailer
        # this is mandatory to check email open/click statuses
        mail.add_custom_arg(CustomArg.new(key: :mail_id,           value: mail_id))
        mail.add_custom_arg(CustomArg.new(key: :community_api_key, value: params.base[:community_sendgrid_key])) if params.base[:community_sendgrid_key]
        mail.add_custom_arg(CustomArg.new(key: :dummy,             value: ENV['SENDGRID_ENV'] == 'testing'))
        mail.add_category(Category.new(name: params.base[:template_name]))
        mail.add_personalization(personalization)
      end
    end

    # file = [:filename, :file_obj]. TODO: use hash instead of array for explicitness
    def build_attachment(file)
      Attachment.new.tap do |attachment|
        attachment.content = Base64.strict_encode64(file[1])
        attachment.type = file[0].split('.')[-1]
        attachment.filename = file[0]
        attachment.disposition = 'attachment'
      end
    end

    def template_id_for(template_name)
      # TODO: raise exception if unexistent name or missing :template_name key
      Constants::Sendgrid::TEMPLATES[template_name]
    end

    def add_cc_and_bcc(params_cc_bcc:, personalization:)
      cc  = params_cc_bcc[:cc_mail]
      bcc = params_cc_bcc[:bcc_mail]

      cc&.each do |mail|
        personalization.add_cc(Email.new(**mail))
      end

      bcc&.each do |mail|
        personalization.add_bcc(Email.new(**mail))
      end

      personalization
    end
  end
end

# TODO: unit tests!
# TODO: raise exception if params.sendgrid_dynamic_data is nil unless static email
