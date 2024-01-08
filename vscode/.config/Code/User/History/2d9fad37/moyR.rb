class AutomatedPaymentNotificationJob < CustomJob
  queue_as :high_ram_queue

  def perform(job_queue: nil, _message: nil)
    communities = communities_to_notify

    communities.each do |comm_id, payments_count|
      community = Community.find(comm_id)
      community_users = community.manager_and_attendant_community_users_with_bills_edit_permission
      byebug
      users = User.with_valid_email.where(id: community_users.pluck(:user_id).uniq, active: true).where.not(sign_in_count: 0)

      users.each do |user|
        NotifyUserWithLinkJob.perform_later(
          _community_id: community.id,
          recipient_id: user.id,
          subject: I18n.t('mailers.automated_payment_notification.subject', community: community.name, not_notified_count: payments_count),
          button: { label: I18n.t('mailers.automated_payment_notification.button'), url: notify_pending_url(user, community) },
          information: information(user.name, payments_count, community.name),
          template_name: SmartLink::SUBJECT_TYPES[:automated_payment_notification],
          _message: I18n.t('jobs.notify_user_with_information_job')
        )
      end
    end
  end

  private

  def notify_pending_url(user, community)
    redirect_path_url = Rails.application.routes.url_helpers.notify_pending_payments_path
    subject_type_url = SmartLink::SUBJECT_TYPES[:automated_payment_notification]

    SmartLinkManager::SmartLinkService.instance.generate_link(user, {}, {}, redirect_path_url, community.id, false, subject_type_url, 5.days.from_now).link
  end

  def information(user_name, not_notified_count, community_name)
    { image_url: I18n.t('mailers.automated_payment_notification.information.image_url'),
      greeting: I18n.t('mailers.automated_payment_notification.information.greeting', name: user_name),
      content: [I18n.t('mailers.automated_payment_notification.information.content', not_notified_count: not_notified_count, community: community_name)] }
  end

  def communities_to_notify
    period_control_communities_ids = Setting.where(code: 'period_control', value: 0).pluck(:community_id)
    no_period_control_communities_ids = Setting.where(code: 'period_control', value: 1).pluck(:community_id)
    enabled_reminder_communities_ids = Setting.where(code: 'payment_notification_reminder', value: 1).pluck(:community_id)

    communities = AutomatedPaymentNotificationQueries.no_period_control_communities_to_notify(no_period_control_communities_ids & enabled_reminder_communities_ids)
    communities + AutomatedPaymentNotificationQueries.period_control_communities_to_notify(period_control_communities_ids & enabled_reminder_communities_ids)
  end
end
