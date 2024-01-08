class AutomatedResidentsSignInNotificationJob < CustomJob
  queue_as :high_ram_queue

  def perform(job_queue: nil, _message: nil)
    to_notify = AutomatedResidentsSignInNotificationQueries.users_to_notify
    users = User.where(id: to_notify.map(&:first)).index_by(&:id)
    communities = Community.where(id: to_notify.map(&:second).uniq).index_by(&:id)
    jobs = []

    to_notify&.each do |user_id, comm_id|
      user = users[user_id]
      community = communities[comm_id]

      jobs << NotifyUserWithLinkJob.new(
        _community_id: community.id,
        recipient_id: user.id,
        subject: I18n.t('mailers.automated_residents_sign_in_notification.subject', community: community.name),
        button: { label: I18n.t('mailers.automated_residents_sign_in_notification.button'), url: login_url(user, community) },
        information: information(user.name),
        category: SmartLink::SUBJECT_TYPES[:automated_residents_sign_in_notification],
        _message: I18n.t('jobs.notify_user_with_information_job')
      )
    end

    CustomJob.enqueue_multiple(jobs)
  end

  private

  def login_url(user, community)
    redirect_path_url = Rails.application.routes.url_helpers.part_owner_property_path
    subject_type_url = SmartLink::SUBJECT_TYPES[:automated_residents_sign_in_notification]

    SmartLinkManager::SmartLinkService.instance.generate_link(user, {}, { resident_login: true }, redirect_path_url, community.id, true, subject_type_url, 3.days.from_now).link
  end

  def information(user_name)
    { image_url: I18n.t('mailers.automated_residents_sign_in_notification.information.image_url'),
      greeting: I18n.t('mailers.automated_residents_sign_in_notification.information.greeting', name: user_name),
      content: [I18n.t('mailers.automated_residents_sign_in_notification.information.content')] }
  end
end
