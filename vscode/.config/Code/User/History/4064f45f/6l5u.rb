class AutomatedFirstPropertyFineGroupReminderJob < BasePropertyFineGroupReminderJob
  private

  def notify
    super do |user, community|
      enqueue_notification(**notification_args(user, community))
    end
  end

  def communities
    byebug
    filtered_communities(base_communities).where.missing(:property_fine_groups).uniq
  end

  def subject_type
    SmartLink::SUBJECT_TYPES[:automated_first_property_fine_reminder]
  end

  def notification_args(user, community)
    {
      subject: I18n.t('mailers.automated_first_property_fine_reminder.subject', community: community.name),
      button: { label: I18n.t('mailers.automated_first_property_fine_reminder.button'), url: create_debt_recurrence_url(user, community) },
      _message: I18n.t('jobs.notify_user_with_information_job'),
      _community_id: community.id,
      recipient_id: user.id,
      information: {
        image_url: I18n.t('mailers.automated_first_property_fine_reminder.information.image_url'),
        greeting: I18n.t('mailers.automated_first_property_fine_reminder.information.greeting', name: user.name),
        content: [I18n.t('mailers.automated_first_property_fine_reminder.information.content', community: community.name)]
      },
      template_name: subject_type
    }
  end
end
