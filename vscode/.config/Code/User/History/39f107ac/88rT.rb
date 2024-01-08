# == Schema Information
#
# Table name: smart_links
#
#  id               :bigint           not null, primary key
#  amount_of_usages :integer          default(0)
#  expiration_date  :datetime
#  extra_data       :json
#  last_use         :datetime
#  link             :string
#  property_user    :boolean
#  redirect_path    :string
#  subject_type     :string
#  token            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  community_id     :bigint
#  user_id          :bigint           not null
#
# Indexes
#
#  index_smart_links_on_community_id  (community_id)
#  index_smart_links_on_token         (token)
#  index_smart_links_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_4f01aa3ae7  (community_id => communities.id)
#  fk_rails_dd8bd70166  (user_id => users.id)
#
class SmartLink < ApplicationRecord
  SUBJECT_TYPES = {
    login_easy_pay: 'login_easy_pay',
    automatic_payment_auto_login: 'automatic_payment_auto_login',
    one_click_subscription_auto_login: 'one_click_subscription_auto_login',
    legacy_payment_portal_auto_login: 'legacy_payment_portal_auto_login',
    online_payment_autologin: 'online_payment_autologin',
    automated_sign_in_notification: 'automated_sign_in_notification',
    automated_payment_notification: 'automated_payment_notification',
    automated_common_expense_notification_reminder: 'automated_common_expense_notification_reminder',
    automated_residents_sign_in_notification: 'automated_residents_sign_in_notification',
    automated_property_fine_reminder: 'automated_property_fine_reminder',
    automated_first_property_fine_reminder: 'automated_first_property_fine_reminder',
    notify_new_property_user: 'notify_new_property_user',
    notify_new_user: 'notify_new_user',
    notify_user_new_post: 'notify_user_new_post',
    notify_user_with_pdf_payment: 'notify_user_with_pdf_payment',
    notify_new_guest_arrival: 'notify_new_guest_arrival',
    notify_published_survey: 'notify_published_survey',
    notify_package_to_user: 'notify_package_to_user',
    notify_property_user_request: 'notify_property_user_request',
    notify_balance: 'notify_balance'
  }.freeze

  def increment_usage_counter(quantity: 1)
    update(amount_of_usages: amount_of_usages + quantity, last_use: Time.current.utc)
  end
end
