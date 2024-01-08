# frozen_string_literal: true

# Notifica a los morosos de las comunidades
class StpPaymentDispersionJob < CustomJob
  include ApplicationHelper
  queue_as do
    Rails.env.production? ? :low_ram_stp_queue : :low_ram_queue
  end

  def perform(_message: I18n.t("jobs.stp_payment_dispertion"), locale: "es", **_extras)
    puts "Dispersing STP payment to the community"
    Rollbar.info(
      I18n.t("jobs.stp_payment_dispertion"),
      nil
    )

    # OnlinePayments::Stp::CfDispertionPaymentSend.new.call
    OnlinePayments::Stp::StpDispertion.new.generate_dispertion
  end
end
