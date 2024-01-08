module Abilities
  module SuperadminAbilities
    class PaymentsPermissionModule < PermissionModule
      PERMANENT_PERMISSIONS = {
        tier_1: {
          Payment: %i[create update nullify hide destroy destroy_assign_payment assign_common_expense assign_payments import],
          ExcelUpload: {
            actions: %i[import_data create],
            filters: {
              name: 'Recaudación'
            }
          }
        },
        tier_2: {
          Property: %i[destroy_business_transaction],
          Debt: %i[destroy]
        }
      }.freeze

      def apply_restrictions
        super

        can %i[new edit], Payment
      end
    end
  end
end
