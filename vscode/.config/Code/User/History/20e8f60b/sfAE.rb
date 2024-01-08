# frozen_string_literal: true

# Módulo para la conexión de servicios externos como HubSpot
module Crm
  # Dependiendo del country_code, esto podría llamar a otro módulo
  module Base
    def self.update_crm_counter(args)
      byebug
      HubSpot.update_counter(**args)
    end
  end
end
