class AutomatedSignInNotificationJob < CustomJob
  queue_as :low_ram_queue

  def perform(_message: nil)
    users = users_to_notify
    users&.each do |user|
      community = user.manageable_community_users.joins(:community).merge(Community.active_and_real).first.community

      NotifyUserWithLinkJob.perform_later(
        _community_id: community.id,
        recipient_id: user.id,
        subject: I18n.t('mailers.automated_sign_in_notification.subject', community: community.name),
        button: { label: I18n.t('mailers.automated_sign_in_notification.button'), url: login_url(user, community) },
        information: information(user.name),
        template_name: SmartLink::SUBJECT_TYPES[:automated_sign_in_notification],
        _message: I18n.t('jobs.notify_user_with_information_job')
      )
    end
  end

  private

  def login_url(user, community)
    redirect_path_url = Rails.application.routes.url_helpers.dashboard_path
    subject_type_url = SmartLink::SUBJECT_TYPES[:automated_sign_in_notification]

    SmartLinkManager::SmartLinkService.instance.generate_link(user, {}, { admin_manager_login: true }, redirect_path_url, community.id, false, subject_type_url, 24.hours.from_now).link
  end

  def information(user_name)
    { image_url: I18n.t('mailers.automated_sign_in_notification.information.image_url'),
      greeting: I18n.t('mailers.automated_sign_in_notification.information.greeting', name: user_name),
      content: [I18n.t('mailers.automated_sign_in_notification.information.content')] }
  end

  def users_to_notify
    User
      .joins(manageable_community_users: :community)
      .merge(Community.active_and_real)
      .distinct
      .with_valid_email
      .where(sign_in_count: 0, mobile_sign_in_count: 0, active: true)
  end
end
