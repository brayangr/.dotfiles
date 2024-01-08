class NewPropertyUserNotificationJob < CustomJob
  queue_as :low_ram_queue

  def perform(property_user_id: nil, _community_id: nil, _message: I18n.t('jobs.new_property_user_notification'))
    return if _community_id.nil? || property_user_id.nil?

    community = Community.find_by(id: _community_id)
    property_user = PropertyUser.find_by(id: property_user_id)

    property = property_user.property
    user = property_user.user

    NotifyUserWithLinkJob.perform_later(
      _community_id: community.id,
      recipient_id: property_user.user.id,
      subject: I18n.t('mailers.new_property_user_notification.subject', community: community.name, property_name: property.name),
      button: { label: I18n.t('mailers.new_property_user_notification.button'), url: login_url(user, community) },
      information: information(property, user),
      template_name: SmartLink::SUBJECT_TYPES[:notify_new_property_user],
      _message: I18n.t('jobs.notify_user_with_information_job')
    )
  end

  private

  def information(property, user)
    {
      content: [I18n.t('mailers.new_property_user_notification.information.content', property_name: property.name)],
      greeting: I18n.t('mailers.new_property_user_notification.information.greeting', name: user.name),
      image_url: I18n.t('mailers.new_property_user_notification.information.image_url')
    }
  end

  def login_url(user, community)
    redirect_path_url = Rails.application.routes.url_helpers.part_owner_property_path
    subject_type_url = SmartLink::SUBJECT_TYPES[:notify_new_property_user]

    SmartLinkManager::SmartLinkService.instance.generate_link(user, {}, { resident_login: true }, redirect_path_url, community.id, true, subject_type_url, 3.days.from_now).link
  end
end
