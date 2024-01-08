class NewUserNotificationJob < CustomJob
  queue_as :low_ram_queue

  def perform(user_id: nil, _community_id: nil, _message: I18n.t('jobs.new_user_notification'))
    return if user_id.nil? || _community_id.nil?

    user = User.find_by(id: user_id)
    community = Community.find_by(id: _community_id)

    NotifyUserWithLinkJob.perform_later(
      _community_id: community.id,
      recipient_id: user.id,
      subject: I18n.t('mailers.new_user_notification.subject', community: community.name),
      button: { label: I18n.t('mailers.new_user_notification.button'), url: login_url(user, community) },
      information: information(user.name),
      template_name: SmartLink::SUBJECT_TYPES[:automated_residents_sign_in_notification],
      _message: I18n.t('jobs.notify_user_with_information_job')
    )
  end

  private

  def login_url(user, community)
    property_user = user.community_users.blank?

    redirect_path_url = case true
                        when user.community_users.where(community_id: community.id).present?
                          Rails.application.routes.url_helpers.dashboard_path
                        when user.property_users.present?
                          Rails.application.routes.url_helpers.part_owner_property_path
                        else
                          Rails.application.routes.url_helpers.communities_path
                        end


    subject_type_url = SmartLink::SUBJECT_TYPES[:automated_residents_sign_in_notification]

    SmartLinkManager::SmartLinkService.instance.generate_link(user,
                                                              {},
                                                              { resident_login: true },
                                                              redirect_path_url,
                                                              community.id,
                                                              property_user,
                                                              subject_type_url,
                                                              3.days.from_now).link
  end

  def information(user_name)
    { image_url: I18n.t('mailers.new_user_notification.information.image_url'),
      greeting: I18n.t('mailers.new_user_notification.information.greeting', name: user_name),
      content: [I18n.t('mailers.new_user_notification.information.content')] }
  end
end
