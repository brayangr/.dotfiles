# == Schema Information
#
# Table name: finkok_responses
#
#  id                         :integer          not null, primary key
#  cadena_original            :string
#  cancelled                  :boolean          default(FALSE)
#  cancelled_at               :datetime
#  company_certificate_number :string
#  company_rfc                :string
#  company_seal               :string
#  complement_status          :integer          default("no_complement")
#  domicilio_fiscal_receptor  :string
#  error_code                 :string
#  error_description          :string
#  estatus_cancelacion        :string
#  estatus_uuid               :string
#  fiscal_regime              :string
#  folio                      :string
#  generated_pdf              :boolean          default(FALSE)
#  grouped                    :boolean          default(FALSE)
#  internal_folio             :integer
#  invoiceable_type           :string
#  irs_at                     :datetime
#  irs_type                   :integer          default("factura")
#  iva                        :float            default(0.0)
#  no_certificado_sat         :string
#  payment_method             :integer          default("PUE")
#  pdf                        :string
#  pdf_updated_at             :datetime
#  receptor_name              :string
#  receptor_rfc               :string
#  receptor_uso_cfdi          :string
#  regimen_fiscal_receptor    :string
#  sat_seal                   :string
#  subtotal                   :float            default(0.0)
#  success                    :boolean          default(FALSE)
#  total                      :float            default(0.0)
#  uuid                       :string
#  xml                        :text
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  invoice_id                 :integer
#  invoiceable_id             :bigint
#  parent_id                  :integer
#  payment_id                 :integer
#
# Indexes
#
#  index_finkok_responses_on_invoiceable                          (invoiceable_type,invoiceable_id)
#  index_finkok_responses_on_invoiceable_id_and_invoiceable_type  (invoiceable_id,invoiceable_type)
#  index_finkok_responses_on_parent_id                            (parent_id)
#  index_finkok_responses_on_payment_id                           (payment_id)
#
# Foreign Keys
#
#  fk_rails_c06461ae5b  (parent_id => finkok_responses.id)
#
class FinkokResponse < ApplicationRecord
  include AttachmentTimerUpdater
  include AttachmentSaver

  belongs_to  :payment, -> { where(finkok_responses: { invoiceable_type: 'Payment' }) }, foreign_key: :invoiceable_id, optional: true
  belongs_to  :finkok_parent, class_name: 'FinkokResponse', foreign_key: :parent_id, optional: true
  belongs_to  :invoiceable, polymorphic: true, optional: true
  has_one     :finkok_complement, -> { where(cancelled: false) }, class_name: 'FinkokResponse', foreign_key: :parent_id
  has_one     :community, through: :payment
  has_one     :complement_community, class_name: 'Community', through: :finkok_parent, source: :community
  has_many    :finkok_response_payments
  has_many    :grouped_payments, through: :finkok_response_payments, source: :payment
  has_many    :grouped_properties, -> { distinct }, through: :grouped_payments, source: :property
  has_one     :complement_payment, class_name: 'Payment', through: :finkok_parent, source: :payment
  before_save :update_error

  scope :cancelled, -> { where(cancelled: true) }
  scope :grouped, -> { where(grouped: true) }
  scope :by_global_folio, lambda { |community_id, global_folio|
    joins(finkok_response_payments: { payment: :period_expense })
      .where(period_expenses: { community_id: community_id }, cancelled: false, grouped: true, success: true)
      .where.not(uuid: nil)
      .where('xml LIKE ?', "%Folio=\"#{global_folio}\"%")
  }
  scope :payments, ->(payments) { where(invoiceable_id: payments.pluck(:id), invoiceable_type: Payment.to_s) }

  mount_uploader :pdf, DocumentationUploader

  enum payment_method: { PUE: 0, PPD: 1 }
  enum complement_status: { no_complement: 0, processing_complement: 1, complement_success: 2, complement_failed: 3, complement_in_queue: 4 }
  enum irs_type: { factura: 0, complemento: 1 }

  def verify_url
    "https://verificacfdi.facturaelectronica.sat.gob.mx/default.aspx?&id=#{uuid}&rr=#{receptor_rfc}&re=#{company_rfc}&tt=#{origin.price}&fe=#{company_seal[-8..-1]}"
  end

  def origin
    if payment?
      invoiceable
    elsif parent_id.present?
      finkok_parent.origin
    elsif grouped_payments.present?
      Payment.new(price: grouped_payments.sum(:price))
    elsif invoice?
      invoiceable
    end
  end

  def update_error
    return unless success

    self.error_code = nil
    self.error_description = nil
  end

  def payment_method_long
    {
      'PUE' => 'PUE - Pago en una sola exhibición',
      'PPD' => 'PPD - Pago por definir'
    }[payment_method]
  end

  def uso_cfdi_to_s
    FiscalIdentification::CFDI_USES[receptor_uso_cfdi]
  end

  def can_create_complement?
    success && !cancelled && PPD? && (no_complement? || complement_failed?)
  end

  def human_complement_status
    FinkokResponse.human_enum_name(:complement_status, complement_status)
  end

  def general_public?
    receptor_name == FiscalIdentification::DEFAULT_FISCAL_VALUES[:general_public_name]
  end

  def generate_uniq_complement(params)
    return if processing_complement?

    update(complement_status: :processing_complement)

    params[:parent_id] = id
    params[:complement] = true
    params[:related_document] = {
      IdDocumento: uuid,
      MonedaDR: 'MXN',
      NumParcialidad: '1',
      ImpSaldoAnt: format('%<num>.2f', num: total.round(2)),
      ImpPagado: format('%<num>.2f', num: total.round(2)),
      ImpSaldoInsoluto: '0',
      EquivalenciaDR: '1',
      ObjetoImpDR: '01'
    }

    response, wicked_pdf = Finkok::Document.new(params).facturar
    self.finkok_complement ||= FinkokResponse.new
    response[:parent_id] = id
    response[:irs_type] = :complemento

    # create file from wicked pdf
    if wicked_pdf.nil?
      finkok_complement.update(response)
    else
      name = "user_temp/factura_pdfs/#{id}_#{Time.now.to_i}.pdf"
      file = File.new(name, 'wb')
      file << wicked_pdf
      file.size
      finkok_complement.pdf = file

      finkok_complement.update(response)

      # clean file
      file.close
      File.delete(name)
    end

    update(complement_status: finkok_complement.success ? :complement_success : :complement_failed)
  end

  def save_pdf_in_amazon(content, paper_size)
    file = WickedPdf.new.pdf_from_string(content, paper_size)

    save_attachment(
      folder_name: 'user_temp/payments/',
      path: "user_temp/payments/#{id}#{Time.now.to_i.to_s[6..10]}.pdf",
      file: file
    )
  end

  def cancel(mx_company, motivo = '02', folio_sustitucion = '')
    response = Finkok::Base.send_cancel(mx_company: mx_company, uuid: uuid, motivo: motivo, folio_sustitucion: folio_sustitucion)

    case response[:estatus_uuid]
    when 'connection_error'
      response[:estatus_cancelacion] = 'Error de conexión'
    when 'no_cancelable'
      response[:estatus_cancelacion] = 'No es posible cancelarlo'
    when '00'
      response[:estatus_cancelacion]
    when '201', '202'
      response[:cancelled] = true
      response[:cancelled_at] = Time.now
      finkok_parent.update(complement_status: :no_complement) if parent_id.present?
    when '205'
      response[:estatus_cancelacion] = 'UUID No encontrado'
    end

    unless response[:canceled] == true
      response[:complement_status] = :complement_failed
      Rollbar.error(response, "#{response[:estatus_uuid]} - #{response[:estatus_cancelacion]}")
    end

    update response
    response
  end

  def nullify_payment(user)
    payment = complemento? ? complement_payment : invoiceable
    community = complemento? ? complement_community : payment.community
    payment.update_columns(nullified: true)

    NullifyPaymentJob.perform_later(
      _community_id: community.id, nullifier_id: user&.id,
      payment_id: payment.id,
      _message: I18n.t(:nullify_payment, scope: %i[jobs]))
  end

  def irs_payment_error
    initial_message = "#{I18n.t('views.commons.error')} #{error_code}:"
    return I18n.t('views.finkok_response.irs_payment_error.error_401', initial_message: initial_message) if error_code == '401'

    "#{initial_message} #{error_description}."
  end

  def payment?
    invoiceable_type == 'Payment'
  end

  def invoice?
    invoiceable_type == 'Invoice'
  end

  def payment_receipt?
    payment? && invoiceable&.receipt.present?
  end

  def uniq_property?
    grouped_payments.distinct.count(:property_id) == 1
  end
end
