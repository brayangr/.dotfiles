module Constants
  module SalaryPayments
    DAILY_OVERTIME_LIMIT = 2
    EMPLOYEE_OLD_ADULT = 65
    NON_CURRENCY_FIELDS = %w[
      costo_adicionales_empresa descuentos descuentos_imponibles haberes haberes_no_imponibles otros_descuentos
      tasa_afp tasa_seguro_cesantia_trabajador total_days_to_work total_missed_days total_worked_days
    ].freeze
    NO_VOLUNTARY_SAVINGS = 'No Cotiza A.P.V.'.freeze
  end
end
