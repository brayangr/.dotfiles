module CalculateSalary
# Module constans
FONASA_PERCENTAGE = 0.07

#params:
#["missed_days"] example => 5
#["base_salary"] example => 200000
#["weekly_hours"] example => 45
#["extra_hours"] examplo => 10
#["percentage_extra_hour"] Must be at least 50%
#["commissions"]
#["bonus"]
#["special_bonus"]
#["advanced_gratification"]
#["isapre"]
#["isapre_plan"]
#["employee_type"] = "Dependiente" o "Independiente"
#["monto_apv"]
#["tipo_contrato"] = "Indefinido", "A plazo fijo", "Obra"
#["num_cargas"] = numero de cargas para asignacion familiar
#["dias_trabajados"]
#["bono_colacion"]
#["bono_movilizacion"]
#["reembolsos"]
#["viaticos"]
#["perdidas_cajas"]
#["desgaste_herramientas"]
#["anticipos"]
#["cuotas_sindicales"]
#["ccaf"]
#["retenciones_legales"]
#["year"]
#["month"]
#["mutual"]
#["regimen_previsional"]
#["isl_value"]

#params = {"is_dependent"=>"si","isapre"=>"cuprum","missed_days"=>5,"base_salary"=>200000,"weekly_hours"=>40,"extra_hours"=>5,"percentage_extra_hour"=>0.5, "commissions" => 0.0,"bonus" => 0.0,"special_bonus"=> 0.0,"advanced_gratification" => 0.0,"isapre_plan" => 0.0, "is_dependent"=> "si", "monto_apv"=> 0, "tipo_contrato"=>"independiente","month"=>4, "year"=>2016, "num_cargas"=>1,"dias_trabajados"=>26,"bono_colacion" => 0,"bono_movilizacion"=>0,"reembolsos"=>20000,"viaticos"=>0,"perdidas_cajas"=>1,"desgaste_herramientas"=>0,"anticipos"=>25000,"cuotas_sindicales"=>0,"ccaf"=>1,"retenciones_legales"=>12}

  def self.remuneraciones(params:, errors: [])
    result = {}

    byebug

    @previred_date = params['use_last_previred_data'] ? PreviredScraper.order(date: :desc).first.date : Date.new(params['year'], params['month'])
    previred = DataScraper.get_data_for_remuneration(date: @previred_date)
    previred = Previred.get_data_from_previred rescue {} unless previred.present?
    result = CalculateSalary.get_imponible_hash(result: result, params: params, previred: previred, errors: errors)
    return errors unless errors.empty?

    result
  end

def self.get_imponible_hash(result:, params:, previred:, errors: [])
  result = CalculateSalary.get_imponible_total(result: result, params: params, previred: previred, errors: errors)
  return errors if !errors.empty?

  result["haberes"] = []
  result["haberes_no_imponibles"] = []
  result["descuentos"] = []
  result["descuentos_imponibles"] = []
  result["otros_descuentos"] = []
  result["costo_adicionales_empresa"] = []

  #NO PAGAR PREVIRED
  result["descuentos_imponibles"] << {name: "Descuento por días perdidos", value: result["disc_missed_days"] }
  result["descuentos_imponibles"] << {name: "Descuento por horas perdidas", value: result["disc_missed_hours"] }
  result["descuentos_imponibles"] << {name: "Descuento por licencia médica", value: result["descuento_licencia_medica"] }

  # Ley de proteccion del empleado
  unless params['protection_law_code'].nil?
    if params['protection_law_code'] == 'reduccion_jornada_laboral'
      result["descuentos_imponibles"] << {name: "Descuento por reducción", value: result["descuento_suspencion_reduccion"] }
    else
      result["descuentos_imponibles"] << {name: "Descuento por suspensión", value: result["descuento_suspencion_reduccion"] }
    end
  end

  #HABERES
  result["haberes"] << { name: "Sueldo base (#{result["total_days_to_work"]} día(s))", value: result["sueldo_base"] }

  result['haberes'] << { name: I18n.t('views.calculate_salary.pdf.missed_days', missed_days: params['missed_days'], count: params['missed_days']), value: -1 * result['disc_missed_days']}
  result['haberes'] << { name: I18n.t('views.calculate_salary.pdf.discount_hours', discount_hours: params['discount_hours'], count: params['discount_hours']), value: -1 * result['disc_missed_hours']}
  result['haberes'] << { name: I18n.t('views.calculate_salary.pdf.dias_licencia', dias_licencia: params['dias_licencia'], count: params['dias_licencia']), value: -1 * result['descuento_licencia_medica']}
  result['haberes'] << { name: I18n.t('activerecord.attributes.salary_payment.aguinaldo'), value: result['aguinaldo'] }
  result['haberes'] << { name: I18n.t('activerecord.attributes.salary_payment.union_pay'), value: result['union_pay'] }

  # Ley de proteccion del empleado
  unless params['protection_law_code'].nil?
    if params['protection_law_code'] == 'reduccion_jornada_laboral'
      result['haberes'] << { name: I18n.t('views.calculate_salary.pdf.dias_reduccion', dias_reduccion: params['suspension_or_reduction_days'], count: params['suspension_or_reduction_days']), value: -1 * result["descuento_suspencion_reduccion"]}
    else
      result['haberes'] << { name: I18n.t('views.calculate_salary.pdf.dias_suspension', dias_suspension: params['suspension_or_reduction_days'], count: params['suspension_or_reduction_days']), value: -1 * result["descuento_suspencion_reduccion"]}
    end
  end

  result["haberes"] << {name: "Horas extra: #{params["extra_hours"]}, #{params["percentage_extra_hour"]}% ", value: result["payment_extra_hours"] }
  result["haberes"] << {name: "Horas extra: #{params["extra_hours_2"]}, #{params["percentage_extra_hour_2"]}% ", value: result["payment_extra_hours_2"] }
  result["haberes"] << {name: "Horas extra: #{params["extra_hours_3"]}, #{params["percentage_extra_hour_3"]}% ", value: result["payment_extra_hours_3"] }

  result["haberes"] << {name: "Comisiones", value: result["commissions"] }
  result["haberes"] << {name: "Bonos", value: result["bonus"] }
  result["haberes"] << {name: "Bonos especiales", value: result["special_bonus"] }
  result["haberes"] << {name: "Bono de responsabilidad", value: result["bono_responsabilidad"] }
  result["haberes"] << {name: "Adelanto de gratificaciones", value: result["get_advanced_gratification"] }
  result["haberes"] << {name: "Gratificaciones anuales", value: result["get_anual_gratification"] }
  result["haberes"] << {name: "Otros bonos imponibles", value: result["otros_bonos_imponibles"] }

  result["haberes"] = result["haberes"] + params["additional_bono"]

  result["haberes_no_imponibles"] << { name: "Asignación familiar", value: result["asignacion_familiar"] }
  result["haberes_no_imponibles"] << { name: "Asignación familiar retroactiva", value: result["asignacion_familiar_retroactiva"] }


  days = params["mov_col_diarios?"] ? "(#{params["bono_days"]} días)" : ""
  result["haberes_no_imponibles"] << { name: "Asignación de colación #{days}", value: result["bono_colacion"]}
  result["haberes_no_imponibles"] << { name: "Asignación de movilización #{days}", value: result["bono_movilizacion"]}
  result["haberes_no_imponibles"] << { name: "Reembolsos", value: result["reembolsos"]}
  result["haberes_no_imponibles"] << { name: "Viáticos", value: result["viaticos"]}
  result["haberes_no_imponibles"] << { name: "Asignación por perdida de caja", value: result["asignacion_perdida_cajas"]}
  result["haberes_no_imponibles"] << { name: "Asignación por desgaste de herramientas", value: result["asignacion_desgaste_herramientas"]}
  result['haberes_no_imponibles'] << { name: I18n.t('activerecord.attributes.salary_payment.nursery'), value: result['nursery'] }
  result['haberes_no_imponibles'] << { name: I18n.t('activerecord.attributes.salary_payment.home_office'), value: result['home_office'] }

  #NO PAGA IMPUESTOS
  result['descuentos'] << { name: "Cotización Isapre (#{params['isapre']}) (#{params['has_isapre'] ? 7 : 0}%)", value: result['cotizacion_obligatoria_isapre'] }
  #Si tiene IPS, no descontamos AFP
  if params['regimen_previsional'] == 'AFP'
    result['descuentos'] << { name: I18n.t('views.calculate_salary.discounts.afp_price', afp: params["afp"] , tasa_afp: result['tasa_afp'] * 100), value: result['cotizacion_afp_dependent'] }
  end
  result['descuentos'] << { name: 'SIS', value: result['sis'] }
  result['descuentos'] << { name: "Seguro de cesantía (#{result['tasa_seguro_cesantia_trabajador'] * 100}%)", value: result['seguro_cesantia_trabajador'] }
  result['descuentos'] << { name: "Cotización trabajo pesado #{params["porcentaje_cotizacion_puesto_trabajo_pesado"]}%", value: result['cotizacion_trabajo_pesado'] }
  result['descuentos'] << { name: "Aporte indemnización sustitutivo #{params["tasa_pactada_sustitutiva"]}%", value: result['aporte_sustitutivo'] }

  result['descuentos'] << { name: "Cotización obligatoria IPS (#{params["tasa_cotizacion_ex_caja"]}%, #{params['ex_caja_regimen']})", value: result['cotizacion_ex_caja_ips'] }
  result['descuentos'] << { name: "Cotización desahucio (#{params["tasa_cotizacion_desahucio_ex_caja"]}%, #{params['ex_caja_regimen_desahucio']})", value: result['cotizacion_desahucio'] }

  if params['tipo_apv'] == 'TipoB'
    result['descuentos'] << { name: 'APV tipo B', value: result['apv'] }
  else
    result["otros_descuentos"] << { name: 'APV tipo A', value: result['apv'] }
  end

  #PAGO IMPUESTO
  result["otros_descuentos"] << {name: "Adicional salud", value: result["adicional_salud"] }
  result["otros_descuentos"] << {name: "Impuestos (IUSC)", value: result["IUSC"] }
  result["otros_descuentos"] << {name: "Cuotas sindicales", value: result["cuotas_sindicales"] }
  result["otros_descuentos"] << {name: "Cuenta de ahorro voluntario AFP", value: result["afp_second_account"] }
  result["otros_descuentos"] << {name: "CCAF #{params['caja']}", value: result['ccaf'] } #DUDA
  result["otros_descuentos"] << {name: "Retenciones judiciales", value: result["retenciones_legales"] }
  result["otros_descuentos"] << {name: "Descuento dental", value: params["descuento_dental_ccaf"] }
  result["otros_descuentos"] << {name:  I18n.t('views.remunerations.previred.leasing_discounts'), value: params["descuento_leasing_ccaf"] }
  result["otros_descuentos"] << {name: "Descuentos por seguro de vida", value: params["descuento_seguro_de_vida_ccaf"] }
  result["otros_descuentos"] << {name: "Otros descuentos", value: params["otros_descuentos_ccaf"] }
  result["otros_descuentos"] << {name: "Descuento cargas familiares", value: params["descuento_cargas_familiares_ccaf"] }

  result["otros_descuentos"] += params["otras_coutas_ccaf"] + params["additional_discount"]

  #EMPRESA PAGA SIN DESCONTAR
  unless params.fetch("employee_age", 0) >= Constants::SalaryPayments::EMPLOYEE_OLD_ADULT
    result["costo_adicionales_empresa"] << {name: "SIS", value: result["empresa_sis"] }
  end

  result["costo_adicionales_empresa"] << {name: "Mutual", value: result["mutual"] }
  result["costo_adicionales_empresa"] << {name: "ISL", value: result["isl"] }
  result["costo_adicionales_empresa"] << {name: "Seguro de cesantía", value: result["seguro_cesantia_empleador"] }
  # result["otros_costos_empresa"] = result["costo_adicionales_empresa"].inject(0){|sum,e| sum+=e[:value]}

  return result
end

def self.get_imponible_total(result:, params:, previred:, errors: [])
  result["total_days_to_work"]             = CalculateSalary.total_days_to_work(params).to_f.round(2)
  result["total_worked_days"]              = CalculateSalary.total_worked_days(params).to_f.round(2)
  result["total_missed_days"]              = CalculateSalary.total_missed_days(params).to_f.round(2)
  result["sueldo_base"]                    = CalculateSalary.get_base_salary(params, result, previred).to_f.round(0)

  #Para Calcular Total Haberes Imponible
  result["disc_missed_days"]               = CalculateSalary.get_desc_inasistencia(params, result, previred)
  result["disc_missed_hours"]              = CalculateSalary.get_desc_inasistencia_hour(params, result, previred).to_f.round(0)
  #Descontar licencia medica del sueldo liquido
  result["descuento_licencia_medica"]      = CalculateSalary.get_licencia_medica(params, result, previred).to_f.round(0)

  #Descontar licencia suspension
  result["descuento_suspencion_reduccion"] = CalculateSalary.get_suspencion(params, result, previred).to_f.round(0)

  result["payment_extra_hours"]            = CalculateSalary.get_extra_hours(params, result, previred).to_f.round(0)
  result["payment_extra_hours_2"]          = CalculateSalary.get_extra_hours_2(params, result, previred).to_f.round(0)
  result["payment_extra_hours_3"]          = CalculateSalary.get_extra_hours_3(params, result, previred).to_f.round(0)

  result["commissions"]                    = CalculateSalary.get_commissions(params, result, previred).to_f.round(0)
  result["bonus"]                          = CalculateSalary.get_bonus(params, result, previred).to_f.round(0)
  result["special_bonus"]                  = CalculateSalary.get_special_bonus(params, result, previred).to_f.round(0)
  result["get_advanced_gratification"]     = CalculateSalary.get_advanced_gratification(params, result, previred).to_f.round(0)
  result["get_anual_gratification"]        = CalculateSalary.get_anual_gratification(params, result, previred).to_f.round(0)
  result["bono_responsabilidad"]           = CalculateSalary.get_bono_responsabilidad(params, result, previred).to_f.round(0)
  result["otros_bonos_imponibles"]         = CalculateSalary.get_otros_bonos_imponibles(params, result, previred).to_f.round(0)
  result['aguinaldo']                      = CalculateSalary.get_aguinaldo(params, result, previred).to_f.round(0)
  result['union_pay']                      = CalculateSalary.get_union_pay(params, result, previred).to_f.round(0)

  # Total Haberes Imponible
  result['imponible_total'] = (
    result['sueldo_base'] -
    result['descuento_licencia_medica'] -
    result['descuento_suspencion_reduccion'] -
    result['disc_missed_hours'] +
    result['payment_extra_hours'] +
    result['payment_extra_hours_2'] +
    result['payment_extra_hours_3'] +
    result['commissions'] +
    result['bonus'] +
    result['special_bonus'] +
    result['get_advanced_gratification'] +
    result['get_anual_gratification'] +
    result['bono_responsabilidad'] +
    result['otros_bonos_imponibles'] +
    result['aguinaldo'] +
    result['union_pay']
  ).to_f

  result['imponible_total'] += params['additional_bono'].inject(0) { |sum, e| sum + e[:value] }

  if (result['imponible_total'] - result['disc_missed_days']).negative?
    result['disc_missed_days'] = result['imponible_total']
    result['imponible_total'] = 0
  else
    result['imponible_total'] -= result['disc_missed_days']
  end


  # Para Calcular Total Haberes Líquidos
  result['cotizacion_obligatoria_isapre'] = CalculateSalary.get_cotizacion_obligatoria_isapre(params, result, previred).to_f.round(0)
  result['cotizacion_obligatoria_isapre_employee_suspension'] = CalculateSalary.get_cotizacion_obligatoria_isapre_employee_suspension(params, result, previred).to_f.round(0)

  result["cotizacion_trabajo_pesado"] = CalculateSalary.get_cotizacion_trabajo_pesado(params, result, previred).to_f.round(0)
  result["renta_imponible_sustitutiva"] = CalculateSalary.get_renta_imponible_sustitutiva(params, result, previred).to_f.round(0)
  result["aporte_sustitutivo"] = CalculateSalary.get_aporte_sustitutivo(params, result, previred).to_f.round(0)


  r_afp = CalculateSalary.get_afp(params, result, previred)
  result['cotizacion_afp_dependent']                     = r_afp['pago_afp'].to_f.round(0)
  result['cotizacion_afp_dependent_employee_suspension'] = r_afp['pago_afp_employee_suspension'].to_f.round(0)
  result['tasa_afp']                                     = r_afp['tasa_afp'].to_f
  result['sis']                                          = r_afp['empleado_sis'].to_f.round(0) # Saldrá en 0.0 si no hay
  result['empresa_sis']                                  = r_afp['empresa_sis'].to_f.round(0) # Saldrá en 0.0 si no hay
  result['empresa_sis_employee_suspension']              = r_afp['empresa_sis_employee_suspension'].to_f.round(0) # Saldrá en 0.0 si no hay
  result['imponible_afp']                                = r_afp['imponible_afp'].to_f.round(0)
  result['apv']                                          = CalculateSalary.get_apv(params, result, previred).to_f.round(0)
  result['employee_suspension_input_amount']             = CalculateSalary.suspension_input_amount(params).to_f.round(0)

  seguro_cesantia = CalculateSalary.get_seguro_cesantia(params, result, previred)
  result['seguro_cesantia_empleador']                      = seguro_cesantia[:empleador].to_f.round(0)
  result['seguro_cesantia_empleador_employee_suspension']  = seguro_cesantia[:empleador_employee_suspension].to_f.round(0)
  result['seguro_cesantia_trabajador']                     = seguro_cesantia[:trabajador].to_f.round(0)
  result['seguro_cesantia_trabajador_employee_suspension'] = seguro_cesantia[:trabajador_employee_suspension].to_f.round(0)
  result['tasa_seguro_cesantia_trabajador']                = seguro_cesantia[:tasa_trabajador].to_f
  result['tasa_seguro_cesantia_trabajador']                = seguro_cesantia[:tasa_trabajador].to_f
  result['imponible_cesantia']                             = seguro_cesantia[:imponible_cesantia]

  result["imponible_mutual"] = CalculateSalary.get_imponible_mutual(params, result, previred).to_f.round(0)
  result["mutual"]           = CalculateSalary.get_mutual(params, result, previred).to_f.round(0)
  result["imponible_ips"]    = CalculateSalary.get_imponible_ips(params, result, previred).to_f.round(0)
  result["imponible_isapre"] = CalculateSalary.get_imponible_isapre(params, result, previred).to_f.round(0)
  result["imponible_ccaf"]   = CalculateSalary.get_imponible_ccaf(params, result, previred).to_f.round(0)
  result["isl"]              = CalculateSalary.get_isl(params, result, previred).to_f.round(0)

  result["cotizacion_ex_caja_ips"] = CalculateSalary.get_cotizacion_ex_caja(params, result, previred).to_f.round(0)

  result["total_imponible_desahucio"] = CalculateSalary.get_total_imponible_desahucio(params, result, previred).to_f.round(0)
  result["cotizacion_desahucio"] = CalculateSalary.get_cotizacion_desahucio(params, result, previred).to_f.round(0)

  # Descuentos
  result['descuentos'] = result['cotizacion_obligatoria_isapre'] + result['cotizacion_afp_dependent'] + result['seguro_cesantia_trabajador']

  ##### Total Haberes Liquidos ####
  result['liq_haberes_total'] = result['imponible_total'] - (result['cotizacion_afp_dependent'] + result['seguro_cesantia_trabajador'])

  ### IPS ##
  result["liq_haberes_total"] -= result["cotizacion_ex_caja_ips"]
  result["liq_haberes_total"] -= result["cotizacion_desahucio"]

  #Restar SIS si es independiente, es 0, si es dependiente. TODO VERIFICAR SI PAGA IMPUESTO
  result["liq_haberes_total"] -= result["sis"]
  result["liq_haberes_total"] -= result["cotizacion_trabajo_pesado"]
  result["liq_haberes_total"] -= result["aporte_sustitutivo"]

  # SOLO EL TIPO B RESTA IMPUESTOS
  result["liq_haberes_total"] -= result["apv"] if params["tipo_apv"] == "TipoB"

  result["asignacion_familiar"] = CalculateSalary.get_asignacion_familiar(params, result, previred)[:asignacion].to_f.round(0)
  result["asignacion_familiar_retroactiva"] = CalculateSalary.get_asignacion_familiar_retroactiva(params, result, previred).to_f.round(0)

  result["bono_colacion"]                    = CalculateSalary.get_bono_colacion(params, result, previred).to_f.round(0)
  result["bono_movilizacion"]                = CalculateSalary.get_bono_movilizacion(params, result, previred).to_f.round(0)
  result["reembolsos"]                       = CalculateSalary.get_reembolsos(params, result, previred).to_f.round(0)
  result["viaticos"]                         = CalculateSalary.get_viaticos(params, result, previred).to_f.round(0)
  result["asignacion_perdida_cajas"]         = CalculateSalary.get_perdidas_cajas(params, result, previred).to_f.round(0)
  result["asignacion_desgaste_herramientas"] = CalculateSalary.get_desgaste_herramientas(params, result, previred).to_f.round(0)
  result['nursery']                          = CalculateSalary.get_nursery(params, result, previred).to_f.round(0)
  result['home_office']                      = params['home_office'].to_f.round(0)

  # Total Sueldo Liquido
  result['sueldo_liq'] = (
    result['liq_haberes_total'] +
    result['asignacion_familiar'] +
    result['asignacion_familiar_retroactiva'] +
    result['bono_colacion'] +
    result['bono_movilizacion'] +
    result['reembolsos'] +
    result['viaticos'] +
    result['asignacion_perdida_cajas'] +
    result['asignacion_desgaste_herramientas'] +
    result['nursery'] +
    result['home_office'] -
    result['cotizacion_obligatoria_isapre']
  )

  # DESPUES DE IMPUESTOS SE LE RESTA EL APV y ADICIONAL DE SALUD
  result["sueldo_liq"] -= result["apv"] if params["tipo_apv"] == "TipoA"

  # Para descuentos de salud
  descuentos_salud = CalculateSalary.get_adicional_salud(params, result, previred)
  result['adicional_salud'] = descuentos_salud[:adicional_salud].round(0)
  result['health_quote_pending'] = descuentos_salud[:health_quote_pending].round(0)
  result['adicional_salud_employee_suspension'] = CalculateSalary.get_adicional_salud_employee_suspension(params, result, previred).to_f.round(0)

  result['sueldo_liq'] -= result['adicional_salud']
  result['liq_haberes_total'] -= [result['adicional_salud'] + result['cotizacion_obligatoria_isapre'], CalculateSalary.max_imponible_salud(previred)].min

  # Para impuesto segunda categoria
  result['IUSC'] = CalculateSalary.get_iusc(params, result, previred, errors).to_f.round(0)
  return errors unless errors.empty?

  result['sueldo_liq'] -= result['IUSC']

  #Para Calcular Total Sueldo Líquido a Pagar
  result["afp_second_account"]  = CalculateSalary.get_afp_second_account(params).to_f.round(0)
  result["anticipos"]           = CalculateSalary.get_anticipos(params, result, previred).to_f.round(0)
  result["cuotas_sindicales"]   = CalculateSalary.get_cuotas_sindicales(params, result, previred).to_f.round(0)
  result["ccaf"]                = CalculateSalary.get_ccaf(params, result, previred).to_f.round(0)
  result["otras_coutas_ccaf"]   = params["otras_coutas_ccaf"].inject(0){|sum,e| sum+=e[:value].to_f}
  result["retenciones_legales"] = CalculateSalary.get_retenciones_legales(params, result, previred).to_f.round(0)
  result["descuentos_previred"] = CalculateSalary.get_descuentos_previred(params, result, previred).to_f.round(0)

  result["sueldo_liq"] -=  (result["afp_second_account"] + result["cuotas_sindicales"] + result["ccaf"] + result["otras_coutas_ccaf"] + result["retenciones_legales"] + result["descuentos_previred"])
  result["sueldo_liq"] -= params["additional_discount"].inject(0){|sum,e| sum+=e[:value]}
  #TOTAL Sueldo Líquido a pagar
  result["sueldo_liq_a_pagar"] = result["sueldo_liq"] - result["anticipos"]

  return result
end

def self.get_base_salary params, result, previred
  if params['daily_wage']
    params["worked_days"].to_f * params["base_salary"].to_f
  elsif params['month'].to_i == params['salary_start_date'].month && params['year'].to_i == params['salary_start_date'].year
    ((30 - (params['salary_start_date'].day - 1)).to_f * params['base_salary'].to_f)/30.0
  else
    params["base_salary"].to_f
  end
end


# params["protection_law_code"]           = self.protection_law_code
# params["suspension_or_reduction_days"]  = self.suspension_or_reduction_days
# params["reduction_percentage"]          = self.reduction_percentage

def self.max_imponible_salud(previred)
  FONASA_PERCENTAGE * previred.dig('RENTA_TI', 'AFP')
end

def self.total_days_to_work params
  if params['daily_wage']
    params["worked_days"]
  elsif params['month'].to_i == params['salary_start_date'].month && params['year'].to_i == params['salary_start_date'].year
    (30 - (params['salary_start_date'].day - 1))
  else
    30
  end
end

def self.previred_suspension_discount(params, colum_percentage, use_informed_rent = false)
  return 0 unless params['employee_protection_law'] || params['protection_law_code'].nil? || params['protection_law_code'] == 'reduccion_jornada_laboral'

  days_to_work = self.total_days_to_work(params).to_f
  suspension_days  = params['suspension_or_reduction_days'].to_f
  amount_to_process = use_informed_rent ? params['afc_informed_rent'].to_f : params['ultimo_total_imponible_sin_licencia'].to_f
  ## this could be a problem if changed from contrato total a parcial
  # Días de suspensión * Renta imponible anterior/30 * percentage * 0,5
  return suspension_days * (amount_to_process / days_to_work) * colum_percentage
end

def self.suspension_input_amount(params)
  return 0 unless params['employee_protection_law'] || params['protection_law_code'].nil? || params['protection_law_code'] == 'reduccion_jornada_laboral'
  days_to_work = self.total_days_to_work(params).to_f
  suspension_days  = params['suspension_or_reduction_days'].to_f
  return (suspension_days * (params['ultimo_total_imponible_sin_licencia'].to_f/days_to_work))
end

def self.total_reduced_percentage_in_days(params)
  #returns float day reduced
  return 0 unless params['employee_protection_law'] || params['protection_law_code'].nil?
  params['reduction_percentage'] = 0 if params['protection_law_code'] != 'reduccion_jornada_laboral'
  (params['suspension_or_reduction_days'].to_f * reduction_percentage(params)).to_f
end

def self.reduction_percentage(params)
  if params['protection_law_code'] == 'reduccion_jornada_laboral'
    params['reduction_percentage'].to_f / 100.0
  else
    (100 - params['reduction_percentage'].to_f) / 100.0
  end
end

def self.total_worked_days params
  days = self.total_days_to_work(params).to_f
  return (days - params["missed_days"].to_f - params["dias_licencia"].to_f - self.total_reduced_percentage_in_days(params) - (params["discount_hours"].to_f / (params["weekly_hours"].to_f / params["days_per_week"].to_f)))
end

def self.total_missed_days(params)
  return params["missed_days"].to_f + params["dias_licencia"].to_f + self.total_reduced_percentage_in_days(params) + (params["discount_hours"].to_f  / (params["weekly_hours"].to_f / params["days_per_week"].to_f))
end

# Metodos Total Haberes Imponibles
def self.get_desc_inasistencia(params, _result, _previred)
  base = params['base_salary'].to_f
  total_worked_days = params['daily_wage'] ? params['worked_days'] : 30
  new_result = params['daily_wage'] ? params['missed_days'].to_f * base : params['missed_days'].to_f * base / total_worked_days.to_f

  CalculateSalary.convert_to_float(new_result)
end

def self.get_desc_inasistencia_hour params, result, previred
  # if params["weekly_hours"].to_i != 0
  #   # DIVIDIR POR HORAS SEMANALES POR 4 SEMANAS
  #   base = params["base_salary"].to_f# + params["bono_colacion"].to_f + params["bono_movilizacion"].to_f
  #   return params["discount_hours"].to_f*base/4/params["weekly_hours"].to_i
  # else
  #   return 0
  # end

  if params["weekly_hours"].to_f == 0
    return 0
  end
  hour_value = CalculateSalary.hour_value params, result, previred
  # VAlor hora x porcentaje extra * cantidad de horas
  return hour_value * params["discount_hours"].to_f
end

def self.get_licencia_medica(params, result, previred)
  base =  result['sueldo_base'].to_f
  total_worked_days = params['daily_wage'] ? params['worked_days'] : 30
  result = params['dias_licencia'].to_f * base / total_worked_days.to_f

  return CalculateSalary.convert_to_float(result)
end

def self.get_suspencion(params, result, previred)
  base =  result['sueldo_base'].to_f
  total_worked_days = params['daily_wage'] ? params['worked_days'] : 30
  result = self.total_reduced_percentage_in_days(params) * base / total_worked_days.to_f

  return CalculateSalary.convert_to_float(result)
end

## Cálculo del proporcional de días de licencia con el último imponible sin licencia, para mutual e ISL (Ley Sanna)
def self.get_proporcional_de_imponible_sin_licencia(params, result, previred)
  if params["dias_licencia"].to_i > 0
    if params["ultimo_total_imponible_sin_licencia"].to_i > 0
      imponible_o_tope = params["ultimo_total_imponible_sin_licencia"].to_i
    else #en caso de no tener informacion historica de liquidaciones sin licincia.
      imponible_o_tope = result["imponible_total"].to_i + result["descuento_licencia_medica"].to_i
    end

    imponible_o_tope = [imponible_o_tope, previred["RENTA_TI"]["AFP"]].min
    desc_licencia_medica_base_mes_anterior = imponible_o_tope * params["dias_licencia"].to_i/30

    return 0.0003 * desc_licencia_medica_base_mes_anterior
  else
    return 0
  end
end

def self.other_imponible_bonuses(params)
  params['additional_bono'].select { |b| b[:checked] }.sum { |b| b[:value] }.to_f
end

def self.hour_value params, result, previred
  hour_value = 0
  if params["daily_wage"]
    if params["days_per_week"].to_f >= 5
      #caso semana corrida
      # 6 días: http://www.dt.gob.cl/consultas/1613/w3-article-60186.html
      # 5 días: http://www.dt.gob.cl/consultas/1613/w3-article-60184.html
      daily_salary = params["base_salary"].to_f + params["base_salary"].to_f/params["days_per_week"].to_f
    else
      daily_salary = params["base_salary"].to_f
    end

    hour_value = daily_salary*params["days_per_week"].to_f/params["weekly_hours"].to_f
  else
    # http://www.dt.gob.cl/consultas/1613/w3-article-95182.html
    # SUELDO /30*28 es para obtener el factor proporcional a 4 semanas y luego div por horas semanales
    hour_value = (params["base_salary"].to_f + params["bono_responsabilidad"].to_f + other_imponible_bonuses(params))/30*28  /(4*params["weekly_hours"].to_f)
  end
  return hour_value
end
def self.get_extra_hours params, result, previred
  if params["weekly_hours"].to_f == 0
    return 0
  end
  hour_value = CalculateSalary.hour_value params, result, previred
  # VAlor hora x porcentaje extra * cantidad de horas
  return hour_value*(1+(params["percentage_extra_hour"].to_f/100 ))* params["extra_hours"].to_f
end
def self.get_extra_hours_2 params, result, previred

  if params["weekly_hours"].to_f == 0
    return 0
  end
  hour_value = CalculateSalary.hour_value params, result, previred
  # VAlor hora x porcentaje extra * cantidad de horas
  return hour_value*(1+(params["percentage_extra_hour_2"].to_f/100 ))* params["extra_hours_2"].to_f

end
def self.get_extra_hours_3 params, result, previred

  if params["weekly_hours"].to_f == 0
    return 0
  end
  hour_value = CalculateSalary.hour_value params, result, previred
  # VAlor hora x porcentaje extra * cantidad de horas
  return hour_value*(1+(params["percentage_extra_hour_3"].to_f/100 ))* params["extra_hours_3"].to_f
end

def self.get_commissions params, result, previred
  return params["commissions"]
end

def self.get_bonus params, result, previred
  return params["bonus"]
end

def self.get_bono_responsabilidad(params, result, previred)
  return params["bono_responsabilidad"]
end
def self.get_otros_bonos_imponibles(params, result, previred)
  return params["otros_bonos_imponibles"]
end


def self.get_special_bonus(params, result, previred)
  return params["special_bonus"]
end

def self.get_advanced_gratification(params, result, previred)
  return params["advanced_gratification"]
end

def self.get_anual_gratification(params, result, previred)
  return params["anual_gratifications"]
end

#Metodos Total Haberes Líquidos
def self.get_cotizacion_obligatoria_isapre(params, result, previred)
  return 0 unless params['has_isapre']

  top = params['has_ips'] ? previred['RENTA_TI']['IPS'] : previred['RENTA_TI']['AFP']
  [result['imponible_total'], top].min.to_f * FONASA_PERCENTAGE
end

#Metodos Total Haberes Líquidos Suspension Previred
  def self.get_cotizacion_obligatoria_isapre_employee_suspension(params, _result, _previred)
    return 0 unless params['has_isapre']

    self.previred_suspension_discount(params, FONASA_PERCENTAGE)
  end

  def self.get_uf_for_period(previred:, month:, year:)
    period = (year * 100 + month).to_s
    previred['UF'][period]
  end

  def self.get_plan_isapre(params:, previred:)
    return params['isapre_plan'].to_f unless params['plan_isapre_en_uf']

    uf = get_uf_for_period(previred: previred, month: CalculateSalary.previred_month, year: CalculateSalary.previred_year)
    (params['isapre_plan'].to_f * uf.to_f).round(0)
  end

  def self.get_adicional_salud(params, result, previred)
    hash = {}
    hash[:adicional_salud] = 0
    hash[:health_quote_pending] = 0
    return hash if params['isapre'].downcase == 'fonasa'

    plan_isapre = get_plan_isapre(params: params, previred: previred)
    por_pagar = plan_isapre - result['cotizacion_obligatoria_isapre'].to_f
    return hash if por_pagar.negative? # PLAN ES MENOR QUE EL 7%

    # SI COTIZA MÁS QUE 7%
    hash[:adicional_salud] = [por_pagar, result['sueldo_liq'].to_f].min
    hash[:health_quote_pending] = por_pagar - hash[:adicional_salud]
    hash
  end

  def self.get_adicional_salud_employee_suspension(params, result, previred)
    return 0 if params['isapre'].downcase == 'fonasa'

    plan_isapre = get_plan_isapre(params: params, previred: previred)
    diferencia = plan_isapre - result['cotizacion_obligatoria_isapre_employee_suspension'].to_f
    return 0 if diferencia.negative? # PLAN ES MENOR QUE EL 7%

    # SI COTIZA MÁS QUE 7%
    monto_adicional = [diferencia, 0].max
    (result['imponible_total'] - monto_adicional).positive? ? monto_adicional : result['imponible_total']
  end

def self.get_afp(params, result, previred)
  # SI NO TIENE AFP (jubilados)
  unless params["has_afp"]
    return { "pago_afp" => 0, "empleado_sis" => 0, "empresa_sis" => 0 }
  end

  imponible_total = result["imponible_total"];

  #Si su regimen previsional no es AFP, el tasa_AFP_dependiente y la tasa del sis las dejamos en 0
  if params['regimen_previsional'] == 'AFP'
    tasa_AFP_dependiente = (params["afp"].present? && previred["AFP"][params["afp"].downcase].present?) ? (previred["AFP"][params["afp"].downcase]["tasa_afp"]).to_f / 100 : 0
    t_sis = (params["afp"].present? && previred["AFP"][params["afp"].downcase].present?) ? previred["AFP"][params["afp"].downcase]["sis"].to_f / 100 : 0
  else
    tasa_AFP_dependiente = 0
    t_sis = 0
  end

  to_pay_sis = 0.0;
  empresa_sis = 0.0;
  empresa_sis_employee_suspension = 0.0;

  #Total a imponer máximo.
  total_a_imponer = [previred["RENTA_TI"]["AFP"], imponible_total].min

  #MONTO A PAGAR A AFP POR DEPENDIENTE
  to_pay_dep = tasa_AFP_dependiente * total_a_imponer
  to_pay_dep_employee_suspension = self.to_pay_dep_employee_suspension(params, tasa_AFP_dependiente, true)

  # total_a_imponer = [previred["RENTA_MI"]["Dep_Ind"],total_a_imponer].max # para el sis

  if params["dias_licencia"].to_i > 0
    if params["ultimo_total_imponible_sin_licencia"].to_i > 0
      imponible_o_tope_empresa = params["ultimo_total_imponible_sin_licencia"].to_i
    else #en caso de no tener informacion historica de liquidaciones sin licincia.
      imponible_o_tope_empresa = result["imponible_total"].to_i + result["descuento_licencia_medica"].to_i
    end
    imponible_o_tope_empresa = [imponible_o_tope_empresa, previred["RENTA_TI"]["AFP"]].min
    total_a_imponer_sis = total_a_imponer + imponible_o_tope_empresa / 30 * params["dias_licencia"].to_i
  else
    total_a_imponer_sis = total_a_imponer
  end

  if params["employee_type"].downcase == "independiente"
    to_pay_sis =   t_sis * total_a_imponer_sis
  else
    empresa_sis =   t_sis * total_a_imponer_sis
    empresa_sis_employee_suspension = self.previred_suspension_discount(params, t_sis, true)
  end

  #RETONAR CUANTO PAGA A AFP (SIS NUNCA ES 0)
  return {
    'pago_afp' => to_pay_dep.round(0),
    'pago_afp_employee_suspension' => to_pay_dep_employee_suspension.round(0),
    'empleado_sis' => to_pay_sis.round(0),
    'empresa_sis' => empresa_sis.round(0),
    'empresa_sis_employee_suspension' => empresa_sis_employee_suspension.round(0),
    'imponible_afp' => total_a_imponer,
    'tasa_afp' => tasa_AFP_dependiente }
end

def self.get_seguro_cesantia(params, result, previred)
  # SI NO TIENE seguro de cesantía (jubilados)
  unless params["has_seguro_cesantia"]
    return {empleador: 0, trabajador: 0}
  end

  if params["dias_licencia"].to_i > 0 && params["ultimo_total_imponible_sin_licencia"].to_i > 0
    imponible_o_tope_empresa = ((result["imponible_total"])+((params["dias_licencia"].to_i/self.total_days_to_work(params).to_f)*(params["ultimo_total_imponible_sin_licencia"].to_i)))
  else
    #Volver a agregar el descuento de licencia medica
    imponible_o_tope_empresa = result["imponible_total"] + result["descuento_licencia_medica"]
  end

  #imponible del trabajador corresponde al imponible pagado en la liquidacion actual
  imponible_o_tope_trabajador = result["imponible_total"]

  imponible_o_tope_trabajador = [previred["RENTA_TI"]["seguro_cesantia"], imponible_o_tope_trabajador].min
  imponible_o_tope_empresa = [previred["RENTA_TI"]["seguro_cesantia"], imponible_o_tope_empresa].min

  if params["employee_type"].downcase == "independiente"
    tasa_trabajador = previred["SEGURO_CESANTIA"]["contrato_indefinido"]["empleador"].to_f / 100 + previred["SEGURO_CESANTIA"]["contrato_indefinido"]["trabajador"].to_f/100
    tasa_empleador = 0.0
  else

    case params["tipo_contrato"] #.downcase
    when "Obra","A plazo fijo"
      tasa_empleador = previred["SEGURO_CESANTIA"]["contrato_plazo_fijo"]["empleador"].to_f / 100 # 3%
      tasa_trabajador = previred["SEGURO_CESANTIA"]["contrato_plazo_fijo"]["trabajador"].to_f / 100 # 3%
    when "Indefinido"
      if params["menor_11_anos"]
        tasa_trabajador = previred["SEGURO_CESANTIA"]["contrato_indefinido"]["trabajador"].to_f/100
        tasa_empleador = previred["SEGURO_CESANTIA"]["contrato_indefinido"]["empleador"].to_f/100
      else
        tasa_empleador = previred["SEGURO_CESANTIA"]["contrato_indefinido_11_anos"]["empleador"].to_f/100
        tasa_trabajador = previred["SEGURO_CESANTIA"]["contrato_indefinido_11_anos"]["trabajador"].to_f/100
      end
    end
  end

  {
    empleador: tasa_empleador * imponible_o_tope_empresa,
    empleador_employee_suspension: self.previred_suspension_discount(params, tasa_empleador),
    tasa_trabajador: tasa_trabajador,
    trabajador: tasa_trabajador * imponible_o_tope_trabajador,
    trabajador_employee_suspension: self.previred_suspension_discount(params, tasa_trabajador),
    imponible_cesantia: imponible_o_tope_empresa
  }
end

def self.get_apv(params, result, previred)
  if params["monto_apv"]
    return [previred["APV"]["tope_mensual"], params["monto_apv"]].min
  end
end

def self.previred_month
  @previred_date.month
end

def self.previred_year
  @previred_date.year
end

#Metodos Total Sueldo Líquido
def self.get_iusc(params, result, previred, error = [])
  # previred["mensual"]
  iusc = previred.dig('IUSC', CalculateSalary.previred_year, CalculateSalary.previred_month, 'mensual')
  return nil if iusc.blank?

  iusc_to_pay = 0.0

  assess_value = result["liq_haberes_total"]
  # Tramo 0 - 611.766
  if assess_value <= iusc[0]["HASTA"]
  iusc_to_pay = (assess_value * iusc[0]["FACTOR"])- iusc[0]["CANTIDAD_A_REBAJAR"]

  # Tramo 611.766 - 1.359.480,00
  elsif assess_value >= iusc[1]["DESDE"] && assess_value <= iusc[1]["HASTA"]
  iusc_to_pay = (assess_value * iusc[1]["FACTOR"])- iusc[1]["CANTIDAD_A_REBAJAR"]

  # Tramo 1.359.480,00 - 2.265.800,00
  elsif assess_value >= iusc[2]["DESDE"] && assess_value <= iusc[2]["HASTA"]
  iusc_to_pay = (assess_value * iusc[2]["FACTOR"])- iusc[2]["CANTIDAD_A_REBAJAR"]

  # Tramo 2.265.800,00 - 3.172.120,00
  elsif assess_value >= iusc[3]["DESDE"] && assess_value <= iusc[3]["HASTA"]
  iusc_to_pay = (assess_value * iusc[3]["FACTOR"])- iusc[3]["CANTIDAD_A_REBAJAR"]

  # Tramo 3.172.120,00 - 4.078.440,00
  elsif assess_value >= iusc[4]["DESDE"] && assess_value <= iusc[4]["HASTA"]
  iusc_to_pay = (assess_value * iusc[4]["FACTOR"])- iusc[4]["CANTIDAD_A_REBAJAR"]

  # Tramo 4.078.440,00 - 5.437.920,00
  elsif assess_value >= iusc[5]["DESDE"] && assess_value <= iusc[5]["HASTA"]
  iusc_to_pay = (assess_value * iusc[5]["FACTOR"])- iusc[5]["CANTIDAD_A_REBAJAR"]

  # Tramo 5.437.920,00 - 6.797.400,00
  elsif assess_value >= iusc[6]["DESDE"] && assess_value <= iusc[6]["HASTA"]
  iusc_to_pay = (assess_value * iusc[6]["FACTOR"])- iusc[6]["CANTIDAD_A_REBAJAR"]

  # Tramo 6.797.400,00 - Infinity
  elsif assess_value >= iusc[7]["DESDE"]
  iusc_to_pay = (assess_value * iusc[7]["FACTOR"])- iusc[7]["CANTIDAD_A_REBAJAR"]
  end

  return iusc_to_pay

end

def self.get_asignacion_familiar(params, result, previred)
  asignacion = 0.0
  tramo = ""
  monto = 0.0

  #CALCULO DEL TRAMO
  # if result["liq_haberes_total"]<=previred["ASIGNACION"][0]["max"]
  #   tramo = "A"
  #   monto = previred["ASIGNACION"][0]["monto"]
 #  elsif result["liq_haberes_total"]>previred["ASIGNACION"][1]["min"] && result["liq_haberes_total"] <= previred["ASIGNACION"][1]["max"]
  #   tramo = "B"
  #   monto = previred["ASIGNACION"][1]["monto"]
 #  elsif result["liq_haberes_total"]>previred["ASIGNACION"][2]["min"] && result["liq_haberes_total"] <= previred["ASIGNACION"][2]["max"]
  #   tramo = "C"
  #   monto = previred["ASIGNACION"][2]["monto"]
  # elsif result["liq_haberes_total"]>previred["ASIGNACION"][3]["min"]
  #   tramo = "D"
  #   monto = previred["ASIGNACION"][3]["monto"]
  # end

  case params["asig_familiar_tramo"]
  when "A"
    monto = previred["ASIGNACION"][0]["monto"]
  when "B"
    monto = previred["ASIGNACION"][1]["monto"]
  when "C"
    monto = previred["ASIGNACION"][2]["monto"]
  when "D"
    monto = previred["ASIGNACION"][3]["monto"]
  else
    monto = 0
  end

  #NO ESTA LO DE SER EL PRIMER O ULTIMO MES, NO SE COMO HACER ESO
  if ( result["total_worked_days"].to_i + params["dias_licencia"].to_f) < 25
    asignacion = monto.to_f * params["num_cargas"].to_f * ((result["total_worked_days"].to_i + params["dias_licencia"].to_f) /30).to_f
  else
    asignacion = monto.to_f * params["num_cargas"].to_f
  end

  return {asignacion: asignacion}
end

def self.get_asignacion_familiar_retroactiva(params, result, previred)
  return params["carga_familiar_retroactiva"].to_f
end

def self.get_imponible_mutual(params, result, previred)
  if params["dias_licencia"].to_i > 0 && params["ultimo_total_imponible_sin_licencia"].to_i > 0
    imponible_total = params["ultimo_total_imponible_sin_licencia"].to_i
  else
    imponible_total = result["imponible_total"];
  end

  return [previred["RENTA_TI"]["AFP"], imponible_total].min
end

def self.to_pay_dep_employee_suspension(params, colum_percentage, use_informed_rent = false)
  return 0 if params['community'].active_employees.count <= 49
  days_to_work = self.total_days_to_work(params).to_f
  suspension_days  = params['suspension_or_reduction_days'].to_f
  amount_to_process = use_informed_rent ? params['afc_informed_rent'].to_f : params['ultimo_total_imponible_sin_licencia'].to_f
  (suspension_days * (amount_to_process/days_to_work) * colum_percentage)
end

def self.get_mutual(params, result, previred)
  return 0 if params["mutual"] == "Sin Mutual" || params["mutual_value"].to_f.zero?

  imponible_final = [ result["imponible_total"], result["imponible_mutual"] ].min

  return ([0.0093, params["mutual_value"].to_f/100].max * imponible_final.to_f) + CalculateSalary.get_proporcional_de_imponible_sin_licencia(params, result, previred).to_f
end

def self.get_imponible_ips(params, result, previred)

  imponible_total = result['imponible_total']

  top = params['has_ips'] ? previred['RENTA_TI']['IPS'] : previred['RENTA_TI']['AFP']

  return [top, imponible_total].min
end

def self.get_imponible_isapre(params, result, previred)
  return 0 if params["isapre"] == "Fonasa"

  return [previred["RENTA_TI"]["AFP"], result["imponible_total"]].min
end

def self.get_imponible_ccaf(params, result, previred)
  return [result["imponible_total"], previred["RENTA_TI"]["AFP"]].min
end

def self.get_isl(params, result, previred)
  return 0 unless result["mutual"].to_i == 0

  return ([0.0093, params["isl_value"].to_f/100].max * result["imponible_total"].to_f) + CalculateSalary.get_proporcional_de_imponible_sin_licencia(params, result, previred).to_f
end

# descontar inasistencia
def self.get_bono_colacion(params, result, previred)
  if params["mov_col_diarios?"]
    return (params["bono_colacion"].to_i*params["bono_days"].to_i).round(0)
  else
    initial_contract_no_worked_days = params['daily_wage'] || !params["first_working_month"] ? 0 : (30 - params['worked_days'])
    dias = params["missed_days"].to_f + params["dias_licencia"].to_f + initial_contract_no_worked_days
    dias = dias + params['suspension_or_reduction_days'] if !params['daily_wage'] && params['employee_protection_law'] && !params['protection_law_code'].nil? && params['protection_law_code'] != 'reduccion_jornada_laboral'
    return (params["bono_colacion"].to_f/30.to_f*(30 - dias)).round(0)
  end
end

# descontar inasistencia
def self.get_bono_movilizacion(params, result, previred)
  if params["mov_col_diarios?"]
    return (params["bono_movilizacion"].to_i*params["bono_days"].to_i).round(0)
  else
    initial_contract_no_worked_days = params['daily_wage'] || !params["first_working_month"] ? 0 : (30 - params['worked_days'])
    dias = params["missed_days"].to_f + params["dias_licencia"].to_f + initial_contract_no_worked_days
    dias = dias + params['suspension_or_reduction_days'] if !params['daily_wage'] && params['employee_protection_law'] && !params['protection_law_code'].nil? && params['protection_law_code'] != 'reduccion_jornada_laboral'
    return (params["bono_movilizacion"].to_f/30.to_f*(30 - dias)).round(0)
  end
end

def self.get_reembolsos(params, result, previred)
  return params["reembolsos"]
end

def self.get_viaticos(params, result, previred)
  return params["viaticos"]
end

def self.get_perdidas_cajas(params, result, previred)
  return params["perdidas_cajas"]
end

def self.get_desgaste_herramientas(params, result, previred)
  return params["desgaste_herramientas"]
end

#Metodos Total Sueldo Líquido a Pagar
def self.get_afp_second_account(params)
  return params["afp_second_account"]
end

def self.get_anticipos(params, result, previred)
  return params["anticipos"]
end

def self.get_cuotas_sindicales(params, result, previred)
  return params["cuotas_sindicales"]
end

def self.get_ccaf(params, result, previred)
  return params["ccaf"]
end

def self.get_retenciones_legales(params, result, previred)
  return params["retenciones_legales"]
end

def self.get_cotizacion_trabajo_pesado(params, result, previred)
  imponible_total = result["imponible_total"]
  # total_a_imponer = imponible_total > previred["RENTA_TI"]["AFP"] ?  previred["RENTA_TI"]["AFP"] : imponible_total

  #MONTO A PAGAR A AFP POR DEPENDIENTE
  return (imponible_total.to_f * params["porcentaje_cotizacion_puesto_trabajo_pesado"].to_f / 100.0).round(0)
end

def self.get_renta_imponible_sustitutiva(params, result, previred)
  imponible_total = result["imponible_total"]
  uf = previred["UF"].max_by{|k,v| k}[1]
  return [90 * uf, imponible_total].min
end

def self.get_aporte_sustitutivo(params, result, previred)
  return (result["renta_imponible_sustitutiva"].to_f * params["tasa_pactada_sustitutiva"].to_f / 100.0).round(0)
end

def self.get_total_imponible_desahucio(params, result, previred)
  imponible_total = result["imponible_total"]
  uf = previred["UF"].max_by{|k,v| k}[1]
  return [60 * uf, imponible_total].min
end

def self.get_cotizacion_desahucio(params, result, previred)
  return params["has_ips"] ? (result["total_imponible_desahucio"].to_f * params["tasa_cotizacion_desahucio_ex_caja"].to_f / 100.0).round(0) : 0
end

def self.get_cotizacion_ex_caja(params, result, previred)
  return params["has_ips"] ? (result["imponible_ips"].to_f * params["tasa_cotizacion_ex_caja"].to_f / 100.0).round(0) : 0
end

def self.get_descuentos_previred(params, result, previred)
  return params["descuento_dental_ccaf"] + params["descuento_leasing_ccaf"] + params["descuento_seguro_de_vida_ccaf"] + params["otros_descuentos_ccaf"] + params["descuento_cargas_familiares_ccaf"]
end

def self.convert_to_float(value)
  begin
    # Convert value to float.
    value = value.to_f.round(0)
  rescue FloatDomainError => e
    value = 0
  end

  value
end

def self.get_nursery(params, result, previred)
  params['nursery']
end

def self.get_union_pay(params, result, previred)
  params['union_pay']
end

def self.get_aguinaldo(params, result, previred)
  params['aguinaldo']
end

end
