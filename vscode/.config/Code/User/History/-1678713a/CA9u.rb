module MailerJobsHelpers
  class NotifySalaryPaymentsHelper < BaseJobHelper
    include OriginInfo
    INSTANCE_VARIABLES = %i[mail_info mail_content_info recipient_info origin_info].freeze

    def mail_info
      {
        bcc_mail:    @event['bcc_mail'],
        community:   community,
        files:       files,
        mail_type:   OutgoingMail.mail_types[:send_with_attachment],
        origin_mail: community.contact_email
      }
    end

    def mail_content_info
      byebug
      {
        contact_phone: community.contact_phone,
        intro:         I18n.t('intro', scope: scope, employee: @event['recipient']['first_name']),
        subject:       I18n.t('subject', scope: scope, year: @event['year'], community: community.name),
        title:         I18n.t('title', scope: scope, year: @event['year'], community: community.name),
        year:          @event['year']
      }
    end

    def recipient_info
      {
        email_to:             recipient['email'],
        recipient_id:         recipient['id'],
        recipient_first_name: recipient['first_name']
      }
    end

    def community
      @community ||= Community.find(@event['community_id'])
    end

    def scope
      @scope = [:mailers, :notify_employee_salary_payment_summary, (@event['year'].present? ? :segmented_by_year : :non_segmented_by_year)]
    end

    def recipient
      @event['recipient']
    end

    def files
      files_hash = @event['files'].each_with_object({}) do |(file_name, file_url), hash|
        hash[file_name] = FileGetter.safe_get_file(file_url)
      end
      files_hash.compact
    end
  end
end
