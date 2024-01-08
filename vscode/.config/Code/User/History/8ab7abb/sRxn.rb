class BasePropertyFineGroupReminderJob < CustomJob
  queue_as :low_ram_queue

  def perform(community_id: nil, _message: nil)
    @community_id = community_id if community_id.present?

    notify
  end

  protected

  attr_reader :community_id

  def notify
    communities.each do |community|
      send_to_admins(community) do |user|
        yield user, community
      end
    end
  end

  def filtered_communities(communities)
    return communities.where(id: community_id) if community_id.present?

    communities
  end

  def base_communities
    communities_ids_without_period_control = Setting.where(code: 'period_control', value: 1).pluck(:community_id)
    communities_ids_enabled_property_fine_group_reminder = Setting.where(code: 'automated_property_fine_group_reminder', value: 1).pluck(:community_id)

    communities_ids_without_period_control_and_enabled_property_fine_group_reminder =
      communities_ids_without_period_control & communities_ids_enabled_property_fine_group_reminder

    Community.where(id: communities_ids_without_period_control_and_enabled_property_fine_group_reminder, active: true, demo: false)
  end

  def create_debt_recurrence_url(user, community)
    SmartLinkManager::SmartLinkService.instance.generate_link(user, {}, {}, redirect_path, community.id, false, subject_type, smart_link_expiration_date).link
  end

  def redirect_path
    Rails.application.routes.url_helpers.new_debit_recurrence_path
  end

  def smart_link_expiration_date
    5.days.from_now
  end

  def subject_type
    raise NotImplementedError
  end

  def enqueue_notification(**kwargs)
    NotifyUserWithLinkJob.perform_later(**kwargs)
  end

  def send_to_admins(community)
    return [] if community.blank?

    community.administrators.where.not(sign_in_count: 0).each do |user|
      yield user
    end
  end
end
