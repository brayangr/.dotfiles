# frozen_string_literal: true

module Remuneration
  module SalaryPayments
    class PreCalculateSalary < StandardServiceObject
      def initialize(salary_payment:, preview: false, run_validate: true)
        super
        @salary_payment = salary_payment
        @preview = preview
        @run_validate = run_validate
      end

      def call
        find_payment_period_expense
        find_community
        find_salary
        assign_ccfa
        calculate_salary
      end

      private

      def preview?
        @preview
      end

      def find_payment_period_expense
        @payment_period_expense = PeriodExpense.find(@salary_payment.payment_period_expense_id)
      end

      def find_community
        @community = @payment_period_expense.community
      end

      def find_salary
        @salary = Salary.find(@salary_payment.salary_id)
      end

      def ccfa_price_amount
        @salary
          .employee
          .social_credit_fees
          .where("social_credits.supplier = ?", @community.ccaf)
          .where(period_expense_id: @salary_payment.payment_period_expense_id)
          .sum(:price)
      end

      def assign_ccfa
        @salary_payment.ccaf = ccfa_price_amount
      end

      def calculate_salary
        previred_errors = []

        byebug
        @calculate_salary_result = ::CalculateSalary.remuneraciones(params: calculate_salary_attributes, errors: previred_errors)

        if previred_errors.any?
          @calculate_salary_result = {}
          @salary_payment.errors.add(:total_imponible, "no pudo ser calculado. #{previred_errors.join('.')}")
        else
          assign_results

          @salary_payment.save(validate: @run_validate) unless preview?
        end

        instantiate(name: :salary_payment, data: @salary_payment)
        instantiate(name: :calculate_salary_result, data: @calculate_salary_result)
      end

      def calculate_salary_attributes
        current_attributes = default_attributes

        @salary.bono_diario_colacion_movilizacion && (current_attributes = with_bono_diario_colacion_movilizacion_attributes(current_attributes))
        @salary_payment.employee_protection_law? && (current_attributes = with_employee_protection_law_attributes(current_attributes))

        current_attributes.with_indifferent_access
      end

      def default_attributes
        {
          # dias_trabajados: @salary_payment.work_days,
          additional_bono: @salary_payment.salary_additional_infos.select{|d| !d.discount}.map { |e| {name: e.name, value: e.value, checked: e.checked}  },
          additional_discount: @salary_payment.salary_additional_infos.select{|d| d.discount}.map { |e| {name: e.name, value: e.value}  },
          advanced_gratification: @salary_payment.advance_gratifications,
          afp: @salary.afp,
          anticipos: @salary_payment.employee.advances.where(period_expense_id: @salary_payment.payment_period_expense_id).sum(:price),
          anual_gratifications: @salary_payment.anual_gratifications,
          asig_familiar_tramo: @salary.asignacion_familiar_tramo,
          base_salary: @salary.base_price,
          bono_colacion: @salary.lunch_benefit,
          bono_movilizacion: @salary.transportation_benefit,
          bono_responsabilidad: @salary_payment.bono_responsabilidad,
          bonus: 0, # @salary_payment.bonus
          caja: @salary_payment.employee.community.ccaf,
          carga_familiar_retroactiva: @salary_payment.carga_familiar_retroactiva,
          ccaf: @salary_payment.ccaf,
          commissions: @salary_payment.commision,
          community: @community,
          cuotas_sindicales: @salary_payment.union_fee,
          daily_wage: @salary.daily_wage,
          days_per_week: @salary.days_per_week,
          desgaste_herramientas: @salary_payment.allocation_tool_wear,
          dias_licencia: @salary_payment.dias_licencia,
          discount_hours: @salary_payment.discount_hours,
          employee_protection_law: @salary_payment.employee_protection_law,
          employee_type: @salary.employee_type,
          ex_caja_regimen: @salary.ex_caja_regimen,
          ex_caja_regimen_desahucio: @salary.ex_caja_regimen_desahucio,
          extra_hours: @salary_payment.extra_hour.to_f,
          extra_hours_2: @salary_payment.extra_hour_2.to_f,
          extra_hours_3: @salary_payment.extra_hour_3.to_f,
          has_afp: @salary.has_afp,
          has_ips: @salary.has_ips,
          has_isapre: @salary.has_isapre,
          has_seguro_cesantia: @salary.has_seguro_cesantia,
          isapre: @salary.isapre,
          isapre_plan: @salary.plan_isapre,
          menor_11_anos: @salary.less_than_11_years(@payment_period_expense.period.end_of_month),
          missed_days: @salary_payment.discount_days,
          month: @payment_period_expense.period.month,
          monto_apv: @salary_payment.apv,
          mov_col_diarios?: false,
          mutual: @payment_period_expense.community.mutual || 'Sin Mutual',
          mutual_value: @payment_period_expense.community.mutual_value,
          isl_value: @payment_period_expense.community.isl_value,
          num_cargas: (@salary.number_of_loads.to_i + @salary.mothernal_number_of_loads.to_i + @salary.invalid_number_of_loads.to_i),
          otros_bonos_imponibles: @salary_payment.otros_bonos_imponible,
          percentage_extra_hour: @salary.additional_hour_price,
          percentage_extra_hour_2: @salary.additional_hour_price_2.to_f,
          percentage_extra_hour_3: @salary.additional_hour_price_3,
          perdidas_cajas: @salary_payment.lost_cash_allocation,
          plan_isapre_en_uf: @salary.plan_isapre_en_uf,
          porcentaje_cotizacion_puesto_trabajo_pesado: @salary.porcentaje_cotizacion_puesto_trabajo_pesado.to_f,
          reembolsos: @salary_payment.refund,
          regimen_previsional: @salary.regimen_previsional,
          retenciones_legales: @salary_payment.legal_holds,
          salary_start_date: @salary_payment.employee.active_salary.start_date,
          special_bonus: @salary_payment.special_bonus,
          tasa_cotizacion_desahucio_ex_caja: @salary.tasa_cotizacion_desahucio_ex_caja,
          tasa_cotizacion_ex_caja: @salary.tasa_cotizacion_ex_caja,
          tasa_pactada_sustitutiva: @salary.tasa_pactada_sustitutiva,
          tipo_apv: @salary_payment.get_tipo_apv,
          tipo_contrato: @salary.contract_type,
          viaticos: @salary_payment.viaticum,
          weekly_hours: @salary.week_hours,
          worked_days: @salary_payment.worked_days,
          year: @payment_period_expense.period.year,
          ultimo_total_imponible_sin_licencia: @salary_payment.ultimo_total_imponible_sin_licencia,
          afp_second_account: @salary.afp_second_account.to_i,
          otras_coutas_ccaf: other_coutas_ccaf,
          nursery: @salary_payment.nursery,
          aguinaldo: @salary_payment.aguinaldo,
          union_pay: @salary_payment.union_pay,
          person_with_disability: @salary.person_with_disability,
          tipo_empleado: @salary.tipo_empleado,
          isapre_codelco: @salary.isapre_codelco,
          number_of_loads: @salary.number_of_loads,
          mothernal_number_of_loads: @salary.mothernal_number_of_loads,
          invalid_number_of_loads: @salary.invalid_number_of_loads,
          subsidy_young_worker: @salary.subsidy_young_worker,
          institucion_apvi: @salary.institucion_apvi,
          institucion_apvc: @salary.institucion_apvc,
          home_office: @salary_payment.home_office,
          employee_age: @salary_payment.employee.get_age,
          descuento_dental_ccaf: @salary.descuento_dental_ccaf.to_i,
          descuento_leasing_ccaf: @salary.descuento_leasing_ccaf.to_i,
          descuento_seguro_de_vida_ccaf: @salary.descuento_seguro_de_vida_ccaf.to_i,
          otros_descuentos_ccaf: @salary.otros_descuentos_ccaf.to_i,
          descuento_cargas_familiares_ccaf: @salary.descuento_cargas_familiares_ccaf.to_i,
          first_working_month: @salary_payment.employee.active_salary.start_date.year == @payment_period_expense.period.year && @salary_payment.employee.active_salary.start_date.month == @payment_period_expense.period.month,
          use_last_previred_data: @salary_payment.use_last_previred_data.eql?('true')
        }
      end

      def other_coutas_ccaf
        @salary
          .employee
          .social_credit_fees
          .where("social_credits.supplier != ? and social_credit_fees.period_expense_id = ?", @salary_payment.employee.community.ccaf, @salary_payment.payment_period_expense_id)
          .group("social_credits.supplier").select("social_credits.supplier as supplier, sum(social_credit_fees.price) as sum_price")
          .map { |e| {name: "CCAF #{e.supplier}", value: e.sum_price} }
      end

      def with_bono_diario_colacion_movilizacion_attributes(attributes)
        attributes[:bono_days]        = @salary_payment.bono_days
        attributes[:mov_col_diarios?] = true
        attributes
      end

      def with_employee_protection_law_attributes(attributes)
        attributes[:protection_law_code]           = @salary_payment.protection_law_code
        attributes[:afc_informed_rent]             = @salary_payment.afc_informed_rent
        attributes[:suspension_or_reduction_days]  = @salary_payment.suspension_or_reduction_days
        attributes[:reduction_percentage]          = @salary_payment.reduction_percentage
        attributes
      end

      def assign_results
        @salary_payment.library_response = { result: @calculate_salary_result, params: calculate_salary_attributes }.to_json

        @salary_payment.result_worked_days               = @calculate_salary_result["total_worked_days"]
        @salary_payment.result_missed_days               = @calculate_salary_result["total_missed_days"]
        @salary_payment.payment_extra_hours_2            = @calculate_salary_result["payment_extra_hours_2"]
        @salary_payment.payment_extra_hours_3            = @calculate_salary_result["payment_extra_hours_3"]
        # @salary_payment.result_bonus                    = @calculate_salary_result["bonus"]
        @salary_payment.bono_responsabilidad             = @calculate_salary_result["bono_responsabilidad"]
        @salary_payment.anual_gratification              = @calculate_salary_result["anual_gratification"]
        @salary_payment.result_disc_missed_days          = @calculate_salary_result["disc_missed_days"]
        @salary_payment.result_disc_missed_hours         = @calculate_salary_result["disc_missed_hours"]
        @salary_payment.cotizacion_obligatoria_isapre    = @calculate_salary_result["cotizacion_obligatoria_isapre"]
        @salary_payment.cotizacion_afp_dependent         = @calculate_salary_result["cotizacion_afp_dependent"]
        @salary_payment.sis                              = @calculate_salary_result["sis"]
        @salary_payment.seguro_cesantia_trabajador       = @calculate_salary_result["seguro_cesantia_trabajador"]
        @salary_payment.result_apv                       = @calculate_salary_result["apv"]
        @salary_payment.result_adicional_salud           = @calculate_salary_result["adicional_salud"]
        @salary_payment.IUSC                             = @calculate_salary_result["IUSC"]
        @salary_payment.empresa_sis                      = @calculate_salary_result["empresa_sis"]
        @salary_payment.seguro_cesantia_empleador        = @calculate_salary_result["seguro_cesantia_empleador"]
        @salary_payment.cotizacion_puesto_trabajo_pesado = @calculate_salary_result["cotizacion_trabajo_pesado"]
        @salary_payment.renta_imponible_sustitutiva      = @calculate_salary_result["renta_imponible_sustitutiva"]
        @salary_payment.aporte_sustitutivo               = @calculate_salary_result["aporte_sustitutivo"]
        @salary_payment.isl                              = @calculate_salary_result["isl"]

        @salary_payment.mutual                           = @calculate_salary_result["mutual"]
        @salary_payment.imponible_mutual                 = @calculate_salary_result["imponible_mutual"]
        @salary_payment.cotizacion_obligatoria_ips       = @calculate_salary_result["cotizacion_ex_caja_ips"]
        @salary_payment.imponible_ips                    = @calculate_salary_result["imponible_ips"]

        @salary_payment.cotizacion_desahucio             = @calculate_salary_result["cotizacion_desahucio"]
        @salary_payment.total_imponible_desahucio        = @calculate_salary_result["total_imponible_desahucio"]

        @salary_payment.imponible_cesantia               = @calculate_salary_result["imponible_cesantia"]
        @salary_payment.imponible_afp                    = @calculate_salary_result["imponible_afp"]
        @salary_payment.imponible_isapre                 = @calculate_salary_result["imponible_isapre"]
        @salary_payment.imponible_ccaf                   = @calculate_salary_result["imponible_ccaf"]

        @salary_payment.payment_special_bonus            = @calculate_salary_result["special_bonus"]
        @salary_payment.payment_extra_hours              = @calculate_salary_result["payment_extra_hours"]

        # Registrar el tramo del a asignación familiar del momento
        @salary_payment.asignacion_familiar_tramo        = @salary.asignacion_familiar_tramo
        @salary_payment.mothernal_number_of_loads        = @salary.mothernal_number_of_loads
        @salary_payment.invalid_number_of_loads          = @salary.invalid_number_of_loads
        @salary_payment.number_of_loads                  = @salary.number_of_loads

        @salary_payment.descuento_licencia               = @calculate_salary_result["descuento_licencia_medica"]

        @salary_payment.total_liquido                    = @calculate_salary_result["sueldo_liq"]
        @salary_payment.total_liquido_a_pagar            = @salary_payment.get_final_rounded_amount(@calculate_salary_result["sueldo_liq_a_pagar"])
        @salary_payment.original_salary_amount_to_pay    = @calculate_salary_result["sueldo_liq_a_pagar"]
        @salary_payment.total_imponible                  = @calculate_salary_result["imponible_total"] #Costo comunidad
        # @salary_payment.haberes_no_imp_comunidad       = @calculate_salary_result["costos_comunidad_no_imponibles"]

        @salary_payment.asignacion_familiar              = @calculate_salary_result["asignacion_familiar"]

        @salary_payment.otros_costos_empresa             = @calculate_salary_result["costo_adicionales_empresa"].inject(0){|sum,e| sum+=e[:value]}

        @salary_payment.haberes_no_imp_comunidad         = @calculate_salary_result["haberes_no_imponibles"].inject(0){|sum,e| sum+=e[:value]}
        @salary_payment.total_haberes                    = @calculate_salary_result["haberes"].inject(0){|sum,e| sum+=e[:value]} #Costo comunidad
        @salary_payment.total_discount                   = @calculate_salary_result["descuentos"].inject(0){|sum,e| sum+=e[:value]}  #Costo comunidad
        @salary_payment.total_discount_2                 = @calculate_salary_result["otros_descuentos"].inject(0){|sum,e| sum+=e[:value].to_i}  #Costo comunidad
        @salary_payment.descuentos_imponibles            = @calculate_salary_result["descuentos_imponibles"].inject(0){|sum,e| sum+=e[:value]}

        #guardar todos los bonos
        @salary_payment.bonus                            = @salary_payment.salary_additional_infos.select{|e| !e.discount }.inject(0){|sum,e| sum+=e[:value]}
        #@salary_payment.validated = true
        @salary_payment.base_salary                      = @calculate_salary_result["sueldo_base"]
        @salary_payment.lunch_benefit                    = @calculate_salary_result["bono_colacion"]
        @salary_payment.transportation_benefit           = @calculate_salary_result["bono_movilizacion"]

        #Employee suspension value
        @salary_payment.cotizacion_afp_dependent_employee_suspension   = @calculate_salary_result["cotizacion_afp_dependent_employee_suspension"]
        @salary_payment.seguro_cesantia_trabajador_employee_suspension = @calculate_salary_result["seguro_cesantia_trabajador_employee_suspension"]
        @salary_payment.result_adicional_salud_employee_suspension     = @calculate_salary_result["adicional_salud_employee_suspension"]
        @salary_payment.empresa_sis_employee_suspension                = @calculate_salary_result["empresa_sis_employee_suspension"]
        @salary_payment.seguro_cesantia_empleador_employee_suspension  = @calculate_salary_result["seguro_cesantia_empleador_employee_suspension"]
        @salary_payment.employee_suspension_input_amount               = @calculate_salary_result["employee_suspension_input_amount"]
        @salary_payment.health_quote_pending                           = @calculate_salary_result['health_quote_pending']
      end
    end
  end
end
