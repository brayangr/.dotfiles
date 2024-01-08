class NotifySlowPayersJob < CustomJob
  queue_as :high_ram_queue
  def perform(_community_id:, _message: I18n.t('jobs.notify_slow_payer_default'))
    community = Community.find(_community_id)
    if community.get_setting_value('period_control').zero?
      Debts::NotifySlowPayersService.call(community: community)
    else
      community.notify_unpaid_debts
    end
  end
end
