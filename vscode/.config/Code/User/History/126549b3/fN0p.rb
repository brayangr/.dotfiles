# frozen_string_literal: true

module Jobs
  # Actualiza contador de CRM de páginas visitadas
  class UpdateCrmCounterJob < LibJob
    def perform
      byebug
      Crm::Base.update_crm_counter(event.symbolize_keys)
    end
  end
end
