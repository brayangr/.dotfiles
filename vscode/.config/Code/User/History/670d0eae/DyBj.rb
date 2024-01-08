class AutomatedPropertyFineGroupReminderJob < BasePropertyFineGroupReminderJob
  LAST_PROPERTY_FINE_GROUP_THRESHHOLD = 32.days.ago

  private

  def notify
    super do |user, community|
      enqueue_notification(**notification_args(user, community, last_fined_at(community)))
    end
  end

  def communities
    communities = base_communities
      .joins(property_fine_groups: :property_fines)
      .group(:id)
      .having('max(property_fines.fined_at) <= ?', LAST_PROPERTY_FINE_GROUP_THRESHHOLD)

    filtered_communities(communities)
  end

  def last_fined_at(community)
    date = ordered_fines(community).pluck('property_fines.fined_at').first
    I18n.l(date, format: '%B-%Y').capitalize
  end

  def ordered_fines(community)
    community
      .property_fine_groups
      .joins(:property_fines)
      .order('property_fines.fined_at desc')
  end

  def subject_type
    SmartLink::SUBJECT_TYPES[:automated_property_fine_reminder]
  end

  def notification_args(user, community, last_fined_at)
    {
      _community_id: community.id,
      recipient_id: user.id,
      subject: I18n.t('mailers.automated_property_fine_reminder.subject', community: community.name),
      button: { label: I18n.t('mailers.automated_property_fine_reminder.button'), url: create_debt_recurrence_url(user, community) },
      _message: I18n.t('jobs.notify_user_with_information_job'),
      information: {
        image_url: I18n.t('mailers.automated_property_fine_reminder.information.image_url'),
        greeting: I18n.t('mailers.automated_property_fine_reminder.information.greeting', name: user.name),
        content: [I18n.t('mailers.automated_property_fine_reminder.information.content', community: community.name, date: last_fined_at)]
      },
      template_name: subject_type
    }
  end
end
