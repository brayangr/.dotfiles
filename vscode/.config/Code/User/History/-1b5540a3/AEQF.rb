# frozen_string_literal: true

module Finkok
  # Manejo de documento de finkok
  class Document
    require 'nokogiri'
    require 'openssl'
    require 'base64'
    require 'open-uri'
    include Constants::FiscalIdentification
    include ScoutApm::Tracer

    IVA = 0.16
    def initialize(params)
      @apply_iva =             params.fetch(:apply_iva, false)
      @complement =            params.fetch(:complement, false)
      @complement_pays_taxes = params.fetch(:complement_pays_taxes, false)
      @folio =                 params.fetch(:folio, nil)
      @mx_company =            params.fetch(:mx_company, nil)
      @parent_id =             params.fetch(:parent_id, nil)
      @payment_code =          params.fetch(:payment_code, '01')
      @payment_method =        params.fetch(:payment_method, 'PUE')
      @payment_params =        params.fetch(:payment_params, nil)
      @periodicity =           params.fetch(:periodicity, {})
      @payment_taxes_params =  params.fetch(:payment_taxes_params, nil)
      @products =              params.fetch(:products, [])
      @receiver_params =       params.fetch(:receiver_params, nil)
      @region =                params.fetch(:region, 'Mexico/General')
      @related_document =      params.fetch(:related_document, nil)
      @serie =                 params.fetch(:serie, nil)
      @paper_size =            params.fetch(:paper_size, page_size: 'A4')
      @grouped =               params.fetch(:grouped, false)

      @subtotal = products.sum { |product| product[:Importe].to_f }.round(2)
      @total_taxes = @apply_iva ? products.sum { |product| (product[:Importe].to_f * IVA).round(2) } : 0
      @total = (@subtotal + @total_taxes - total_discount).round(2)

      @header_params = {
        'xmlns:cfdi': 'http://www.sat.gob.mx/cfd/4',
        'xmlns:xsi':  'http://www.w3.org/2001/XMLSchema-instance',
        Version:      '4.0',
        Serie:        @serie,
        Folio:        @folio,
        Fecha:        (TZInfo::Timezone.get(@region).now - 5.minutes).strftime('%Y-%m-%dT%H:%M:%S'),
        SubTotal:     @subtotal.zero? ? '0' : decimal(amount: @subtotal),
        Moneda:       @complement ? 'XXX' : 'MXN',
        Total:        @total.zero? ? '0' : decimal(amount: @total)
      }.merge(@mx_company.certificate_hash).merge(factura_params)
    end

    def products
      if @complement
        [
          {
            ClaveProdServ: '84111506',
            Cantidad:      '1',
            ClaveUnidad:   'ACT',
            Descripcion:   'Pago',
            ValorUnitario: '0',
            Importe:       '0',
            ObjetoImp:     '01'
          }
        ]
      else
        @products
      end
    end

    def prepare_receiver_params
      return @receiver_params unless publico_general? || @receiver_params[:DomicilioFiscalReceptor].nil?

      @receiver_params.merge!(DomicilioFiscalReceptor: @mx_company.certificate_hash[:LugarExpedicion])

      @receiver_params.merge!(Nombre: 'PUBLICO GENERAL') if publico_general? && @complement # This patch is a response to a Finkok issue.

      @receiver_params
    end

    def factura_params
      if @complement
        {
          'xsi:schemaLocation': 'http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd http://www.sat.gob.mx/Pagos20 http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd',
          'xmlns:pago20':       'http://www.sat.gob.mx/Pagos20',
          TipoDeComprobante:    'P',
          Exportacion:          '01'
        }

      else # factura
        {
          'xsi:schemaLocation': 'http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd',
          TipoDeComprobante:    'I',
          FormaPago:            @payment_method == 'PPD' ? '99' : @payment_code,
          MetodoPago:           @payment_method,
          CondicionesDePago:    'CONDICIONES',
          Exportacion:          '01',
          Descuento:            decimal(amount: total_discount)
        }
      end
    end

    def global_information
      current_time = TimeZone.get_local_time(date_time: @payment_params&.dig(:paid_at) || Time.now, community: @mx_company.community).utc
      month = @periodicity[:month] || current_time.strftime("%m")
      periodicity = @periodicity[:type] || @mx_company.periodicity

      {
        Meses: MxCompany.get_month_by_periodicity(month, periodicity),
        Año: current_time.strftime("%Y"),
        Periodicidad: periodicity
      }
    end

    def publico_general?
      @receiver_params[:Nombre] == DEFAULT_FISCAL_VALUES[:general_public_name]
    end

    def apply_taxes?
      products.none? { |product| product[:ObjetoImp] == '01' }
    end

    def skip_taxes?(product)
      product[:ObjetoImp] == '01'
    end

    def total_discount
      products.sum { |product| product[:Descuento].to_f }.round(2)
    end

    def decimal(amount: 0, decimals: 2)
      format("%<num>.#{decimals}f", num: amount)
    end

    def facturar
      xml_builder = generate_xml
      sello, cadena_original = sellar(xml_builder.doc)
      xml_builder.doc.children[0].set_attribute('Sello', sello)

      response = send_file(xml_builder.to_xml)

      response[:grouped] = @grouped

      unless response[:error_code].present?
        response[:cadena_original] = cadena_original
        response[:company_seal] = sello
        response[:company_rfc] = @mx_company.rfc
        response[:company_certificate_number] = @mx_company.certificate_number
        response[:receptor_rfc] = @receiver_params[:Rfc]
        response[:receptor_name] = @receiver_params[:Nombre]
        response[:regimen_fiscal_receptor] = @receiver_params[:RegimenFiscalReceptor]
        response[:domicilio_fiscal_receptor] = @receiver_params[:DomicilioFiscalReceptor]
        response[:receptor_uso_cfdi] = @receiver_params[:UsoCFDI]
        response[:fiscal_regime] = @mx_company.fiscal_regime
        response[:success] = true
        response[:subtotal] = @subtotal
        response[:iva] = @total_taxes
        response[:total] = @total
        response[:payment_method] = @payment_method
        response[:folio] = @folio

        pdf = generate_pdf response
      end
      [response, pdf]
    end

    def generate_xml
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml['cfdi'].Comprobante(@header_params) do
          xml['cfdi'].InformacionGlobal(global_information) if publico_general? && !@complement
          xml['cfdi'].Emisor(@mx_company.finkok_issuer)
          xml['cfdi'].Receptor(prepare_receiver_params)
          xml['cfdi'].Conceptos do
            products.each do |p|
              base = decimal(amount: p[:Importe].to_f.round(2))
              tax = @apply_iva ? decimal(amount: (p[:Importe].to_f * IVA).round(2)) : 0
              xml['cfdi'].Concepto(p) do
                unless @complement || skip_taxes?(p)
                  xml['cfdi'].Impuestos do
                    xml['cfdi'].Traslados do
                      if @apply_iva
                        xml['cfdi'].Traslado(
                          Base: base, Impuesto: '002',
                          TipoFactor: 'Tasa', TasaOCuota: '0.160000', Importe: tax
                        )
                      else
                        xml['cfdi'].Traslado(Base: base, Impuesto: '002', TipoFactor: 'Exento')
                      end
                    end
                  end
                end
              end
            end
          end
          if @complement
            xml['cfdi'].Complemento do
              xml['pago20'].Pagos(Version: '2.0') do
                if @complement_pays_taxes
                  xml['pago20'].Totales(
                    MontoTotalPagos: decimal(amount: @payment_params[:Monto]),
                    TotalTrasladosBaseIVA16: decimal(amount: @payment_taxes_params[:Base]),
                    TotalTrasladosImpuestoIVA16: decimal(amount: @payment_taxes_params[:Importe])
                  )
                else
                  xml['pago20'].Totales(MontoTotalPagos: decimal(amount: @payment_params[:Monto]))
                end
                xml['pago20'].Pago(@payment_params.merge(TipoCambioP: '1')) do
                  xml['pago20'].DoctoRelacionado(@related_document) do
                    if @complement_pays_taxes
                      xml['pago20'].ImpuestosDR do
                        xml['pago20'].TrasladosDR do
                          xml['pago20'].TrasladoDR(@payment_taxes_params.transform_keys { |key| "#{key}DR".to_sym })
                        end
                      end
                    end
                  end
                  if @complement_pays_taxes
                    xml['pago20'].ImpuestosP do
                      xml['pago20'].TrasladosP do
                        xml['pago20'].TrasladoP(@payment_taxes_params.transform_keys { |key| "#{key}P".to_sym })
                      end
                    end
                  end
                end
              end
            end
          elsif apply_taxes?
            xml['cfdi'].Impuestos(
              TotalImpuestosTrasladados: decimal(amount: @total_taxes)
            ) do
              xml['cfdi'].Traslados do
                xml['cfdi'].Traslado(
                  Base: decimal(amount: @subtotal), Impuesto: '002', TipoFactor: 'Tasa', TasaOCuota: '0.160000',
                  Importe: decimal(amount: @total_taxes)
                )
              end
            end
          end
        end
      end
    end

    def generate_pdf(response)
      args = {
        title:              @complement ? I18n.t('finkok.document.complement') : @mx_company.finkok_issuer[:Nombre],
        first_table:        {
          issuer_rfc:         @mx_company.finkok_issuer[:Rfc],
          folio:              response[:uuid],
          issuer_name:        @mx_company.finkok_issuer[:Nombre],
          certificate_number: @mx_company.certificate_hash[:certificate_number],
          receiver_rfc:       @receiver_params[:Rfc],
          receiver_name:      @receiver_params[:Nombre],
          issuer_postal_code: @mx_company.certificate_hash[:LugarExpedicion],
          cfdi_use:           "#{@receiver_params[:UsoCFDI]} - #{CFDI_USES[@receiver_params[:UsoCFDI]]}",
          receipt_type:       receipt_type,
          fiscal_regime:      "#{@mx_company.fiscal_regime} - #{FISCAL_REGIMES[@mx_company.fiscal_regime]}",
          emitted_at:         response[:irs_at].strftime('%d/%m/%Y - %H:%M:%S')
        },
        products:           products,
        summary_info:       summary_info,
        company_seal:       response[:company_seal],
        sat_seal:           response[:sat_seal],
        cadena_original:    response[:cadena_original],
        no_certificado_sat: response[:no_certificado_sat],
        irs_at:             response[:irs_at],
        RfcProvCertif:      rfc_certificate_supplier(response[:xml]),
        qr:                 RQRCode::QRCode.new(verify_url(response), level: :m, size: 10),
        verify_url:         verify_url(response)
      }

      if @complement
        args[:payment_info] = payment_info
        args[:related_document] = related_document
      else
        args[:total_in_letter] = I18n.t('finkok.document.total_in_letters', integer_part: @total.to_i.to_words.upcase, decimal_part: (@total.modulo(1) * 100).round(0))
      end

      view =
        ApplicationController.render(
          template: 'finkok_responses/show',
          layout: 'pdf',
          formats: [:pdf],
          assigns: args
        )
      WickedPdf.new.pdf_from_string(view, @paper_size)
    end

    def verify_url(response)
      "https://verificacfdi.facturaelectronica.sat.gob.mx/default.aspx?&id=#{response[:uuid]}&rr=#{@receiver_params[:Rfc]}&re=#{@mx_company.finkok_issuer[:Rfc]}&tt=#{@total}&fe=#{response[:company_seal][-8..-1]}"
    end

    def receipt_type
      case factura_params[:TipoDeComprobante]
      when 'I' then 'I - Ingreso'
      when 'P' then 'P - Pago'
      end
    end

    def rfc_certificate_supplier(xml)
      start = xml.index 'RfcProvCertif'
      xml[start + 15..start + 26]
    end

    def summary_info
      var = {}
      var[:Subtotal]  = @SubTotal
      var[:Descuento] = total_discount unless @complement
      var[:IVA]       = @total_taxes unless @complement
      var[:Total]     = @total
      var
    end

    def payment_info
      {
        'Forma de pago' => Finkok::Base.metodos_de_pago[@payment_params[:FormaDePagoP]],
        'Fecha de pago' => @payment_params[:FechaPago][0..9],
        'Moneda'        => @payment_params[:MonedaP],
        'Monto'         => @payment_params[:Monto]
      }
    end

    def related_document
      {
        'Id documento'                             => @related_document[:IdDocumento],
        'Moneda'                                   => @related_document[:MonedaDR],
        'Número parcialidad'                       => @related_document[:NumParcialidad],
        'Método de pago del documento relacionado' => @related_document[:MetodoDePagoDR],
        'Importe de saldo anterior'                => @related_document[:ImpSaldoAnt],
        'Importe pagado'                           => @related_document[:ImpPagado],
        'Importe de saldo insoluto'                => @related_document[:ImpSaldoInsoluto],
        'Equivalencia del documento relacionado'   => @related_document[:EquivalenciaDR]
      }
    end

    def sellar(doc)
      # SAT STYLE
      xslt  = Nokogiri::XSLT(File.read("#{Rails.root}/app/lib/finkok/cadenaoriginal_4_0.xslt"))
      text  = xslt.transform(doc).to_s

      cadena_original = text.gsub("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", '').gsub("\n", '').gsub('&quot;', '"').gsub('&lt;', '<').gsub('&gt;', '>').gsub('&apos;', '´').gsub('&amp;', '&').strip

      # KEY
      pem = Finkok::Base.der_to_pem('ENCRYPTED PRIVATE KEY', @mx_company.csd_key.read)
      key = OpenSSL::PKey::RSA.new(pem, @mx_company.csd_password)
      seal = Base64.encode64(key.sign(OpenSSL::Digest.new('SHA256'), cadena_original)).gsub(/\n/, '')
      [seal, cadena_original]
    end

    def send_file(archivo)
      params = {
        xml:      Base64.encode64(archivo.gsub(/\n/, '')),
        username: ENV['FINKOK_USER'],
        password: ENV['FINKOK_PASSWORD']
      }

      url = "https://#{ENV['FINKOK_SUBDOMAIN']}.finkok.com/servicios/soap/stamp.wsdl"

      client = Savon.client(wsdl: url, log_level: :error)
      response = client.call :stamp, message: params

      data = response.body[:stamp_response][:stamp_result]

      if data[:incidencias]
        error = data[:incidencias][:incidencia]
        error = error[0] if error.is_a?(Array)
        Rollbar.log('error', error)
        return { error_description: error[:mensaje_incidencia], error_code: error[:codigo_error] }
      end

      {
        uuid:               data[:uuid],
        sat_seal:           data[:sat_seal],
        no_certificado_sat: data[:no_certificado_sat],
        irs_at:             data[:fecha],
        xml:                data[:xml]
      }
    end
    instrument_method :send_file, type: 'Finkok::Document'
  end
end
