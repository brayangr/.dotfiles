module Users
  class NotifyNewUserService < ApplicationService
    def initialize(community, user_id, is_resident: true)
      @community = community
      @user_id = user_id
      @is_resident = is_resident
    end

    def call
      return unless @community.present? && @user_id.present?
      return if @is_resident && !@community.old_enough_to_notify_users_creation?

      user = User.find_by(id: @user_id)
      return if user&.email.blank?

      NewUserNotificationJob
        .set(wait: Constants::AttemptsJobs::NEW_USER_NOTIFICATION[:wait])
        .perform_later(user_id: @user_id, _community_id: @community.id, _message: I18n.t('jobs.new_user_notification'))
    end
  end
end
