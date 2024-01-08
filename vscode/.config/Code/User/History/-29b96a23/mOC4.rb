# frozen_string_literal: true

module MailerJobsHelpers
  class NotifyUserWithLinkHelper < BaseJobHelper
    def base
      super(community).merge(
        email_to:      ENV['TESTING_EMAIL_TO'] || recipient.email,
        subject:       @event['subject'],
        template_name: @event['template_name'] || :notify_user_with_link
      )
    end

    def outgoing_mail
      super(community).merge(
        mail_type:      OutgoingMail.mail_types[:notify_user_administrator],
        recipient_id:   recipient.id,
        recipient_type: 'User'
      )
    end

    def sendgrid_dynamic_data
      super(community: community, recipient_name: recipient.first_name).tap do |dynamic_data|
        dynamic_data.merge!(
          intro:  intro,
          button: button,
          ending: {
            goodbye:        I18n.t('mailers.end_mail.content_v2'),
            smile_face_url: I18n.t('mailers.shared.imgs.smile_face_icon')
          },
          footer: admin_footer
        )
      end
    end

    def recipient
      @recipient ||= User.find(@event['recipient_id'])
    end

    def intro
      @intro ||= {
        image_url: @event['information']['image_url'],
        greeting:  @event['information']['greeting'],
        content:   @event['information']['content']
      }
    end

    def button
      @button ||= {
        label: @event['button']['label'],
        url:   @event['button']['url']
      }
    end
  end
end
