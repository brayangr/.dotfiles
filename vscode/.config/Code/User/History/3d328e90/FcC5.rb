class AutomatedCommonExpenseNotificationReminderJob < CustomJob
  queue_as :low_ram_queue

  def perform(_message: nil)
    emails_sent = 0

    communities_to_notify.each do |community|
      last_closed_period_expense = community.last_closed_period_expense
      notify = last_closed_period_expense.common_expense_generated_at.to_date <= 1.day.ago &&
               last_closed_period_expense.bill_notified_at.blank? &&
               last_closed_period_expense.bill_generated &&
               !last_closed_period_expense.initial_setup

      next unless notify

      community_users = community.manager_and_attendant_community_users_with_bills_edit_permission.joins(:user).merge(User.with_valid_email)

      community_users.each do |community_user|
        emails_sent += 1
        user = community_user.user
        locale_translation = translation_by_country(community)

        NotifyUserWithLinkJob.perform_later(
          _community_id: community.id,
          recipient_id: user.id,
          subject: I18n.t('mailers.automated_common_expense_notification_reminder.subject', community: community.name, locale: locale_translation),
          button: { label: I18n.t('mailers.automated_common_expense_notification_reminder.button', locale: locale_translation), url: notify_bills_url(user, community) },
          information: information(user_name: user.name, community: community, last_closed_period_expense: last_closed_period_expense),
          template_name: SmartLink::SUBJECT_TYPES[:automated_common_expense_notification_reminder],
          _message: I18n.t('jobs.notify_user_with_information_job')
        )
      end
    end

    puts("\n\nEmails sent: #{emails_sent}\n\n")
  end

  private

  def notify_bills_url(user, community)
    redirect_path_url = Rails.application.routes.url_helpers.notify_emails_bills_path
    subject_type_url = SmartLink::SUBJECT_TYPES[:automated_common_expense_notification_reminder]

    SmartLinkManager::SmartLinkService.instance.generate_link(user, {}, { from_reminder_mail: true }, redirect_path_url, community.id, false, subject_type_url, 24.hours.from_now).link
  end

  def information(user_name:, community:, last_closed_period_expense:)
    { image_url: I18n.t('mailers.automated_common_expense_notification_reminder.information.image_url'),
      greeting: I18n.t('mailers.automated_common_expense_notification_reminder.information.greeting', name: user_name),
      content: [I18n.t('mailers.automated_common_expense_notification_reminder.information.content',
                       community_name: community.name,
                       last_closed_period_expense: last_closed_period_expense.to_s,
                       locale: translation_by_country(community))] }
  end

  def translation_by_country(community)
    case community.get_locale
    when 'es-MX'
      'es-MX'
    when 'es-EC'
      'es-EC'
    else
      'es-CL'
    end
  end

  def communities_to_notify
    communities_ids_period_control = Setting.where(code: 'period_control', value: 0).pluck(:community_id)
    communities_ids_enabled_reminder = Setting.where(code: 'common_expense_notification_reminder', value: 1).pluck(:community_id)
    communities_ids_period_control_and_enabled_reminder = communities_ids_period_control & communities_ids_enabled_reminder

    communities = Community.where(id: communities_ids_period_control_and_enabled_reminder, active: true, demo: false)

    communities
      .joins(:period_expenses)
      .includes(:period_expenses)
      .where(period_expenses: { enable: true })
      .distinct
  end
end
