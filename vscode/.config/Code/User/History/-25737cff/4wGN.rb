class NotifyUserWithLinkJob < CustomServerlessJob
  queue_as :serverless_queue

  def perform(_community_id:, recipient_id:, information:, button:, subject:, template_name:, _message: I18n.t('jobs.notify_user_with_information_job')); end
end
