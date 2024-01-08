# frozen_string_literal: true

class GeneratePasPdfJob < CustomJob
  queue_as :low_ram_queue

  def perform(_community_id:, _message:, options: {}, pas_id:, pdf_hash:)
    community = Community.find(_community_id)
    property_account_statement = PropertyAccountStatement.find(pas_id)

    PropertyAccountStatementPdfGenerationLib.generate_pdf(property_account_statement, pdf_hash, community: community, property: property_account_statement.property)
    property_account_statement.reload.notify if options[:notify]
    if options[:notify_slow_payer]
      property_account_statement.property.notify_users_with_unpaid_debts(property_account_statement.amount_charged)
    end
  end
end
