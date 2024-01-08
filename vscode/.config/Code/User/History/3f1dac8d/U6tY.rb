# frozen_string_literal: true

# WARNING: Due to incompatibilities between ruby 3.2 and ActionMailer 6.1
#          the module UserMailerParamsAdapter was created, if you add a new
#          mailer method add the name of the method to UserMailerParamsAdapter#METHODS.
#
#          In a future update if Jets use rails 7 dependencies it should work without
#          the "prepend UserMailerParamsAdapter" line.
class UserMailer < ActionMailer::Base
  include HtmlToPlainText
  include TimeZone

  prepend UserMailerParamsAdapter

  helper_method :convert_to_text

  CUSTOM_TEMPLATE_MAIL_TYPES = [
    OutgoingMail.mail_types[:notify_user_event],
    OutgoingMail.mail_types[:send_with_attachment],
    OutgoingMail.mail_types[:notify_user_without_attachment]
  ].freeze

  FOOTER_TYPE = %i[
    admin_to_owner
    admin_to_worker
    cf_to_admin
  ].freeze

  def process_action(_action, params)
    @community_love_messages = params[:community_love_messages]
    @bcc_mail = params[:bcc_mail]
    @testing_email = ENV['TESTING_EMAIL']
    @notifications_from_email = 'notificaciones@mail.comunidadfeliz.com'
    @support_email = 'soporte@comunidadfeliz.com'
    @finance_email = Constants::Email::ADDRESS[:finance]
    @contact_name = params[:contact_name]
    @contact_phone = params[:contact_phone]
    @site_url = 'https://app.comunidadfeliz.com'
    @from = @testing_email || @notifications_from_email

    super
  end

  before_action :set_email_with_redesign, only: %i[
    notify_account_summary_sheet
    notify_bill
    notify_close_common_expense
    notify_employee_salary_payment_summary
    notify_global_finkok_response
    notify_importation_complete
    notify_payment_with_pdf_and_xml
    notify_pdf_payment_receipts
    notify_transfers_excel
    notify_admin_block_date_postponed
  ]

  before_action :set_from_email, only: %i[
    mail_with_pdf_as_attachment
    notify_account_summary_sheet
    notify_admin_message
    notify_bill
    notify_close_common_expense
    notify_email_confirmation
    notify_employee_salary_payment_summary
    notify_first_password
    notify_importation_complete
    notify_global_finkok_response
    notify_irs_billed
    notify_new_superadmin
    notify_payment_with_pdf_and_xml
    notify_pdf_payment_receipts
    notify_product_receipt_pdf
    notify_property_fine
    notify_published_survey
    notify_recover_password
    notify_undo_payments_excel
    notify_user_administrator
    notify_user_event_created
    notify_user_with_pdf_as_attachment
    notify_transfers_excel
  ]

  after_action :send_outgoing_mail, only: %i[
    mail_with_pdf_as_attachment
    notify_account_summary_sheet
    notify_admin_message
    notify_bill
    notify_close_common_expense
    notify_email_confirmation
    notify_employee_salary_payment_summary
    notify_first_password
    notify_global_finkok_response
    notify_importation_complete
    notify_payment_with_pdf_and_xml
    notify_product_receipt_pdf
    notify_property_fine
    notify_recover_password
    notify_undo_payments_excel
    notify_user_administrator
    notify_user_event_created
    notify_user_with_pdf_as_attachment
    notify_transfers_excel
    notify_admin_block_date_postponed
  ], unless: -> { @skip }

  after_action :attach_xml, only: [:notify_global_finkok_response, :notify_payment_with_pdf_and_xml]

  def notify_account_summary_sheet(params_helper:)
    params_helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end
    @footer_type = FOOTER_TYPE[0]
  end

  def notify_account_updated(account_args:, communities_names:, contact_emails:)
    @title = t(:title, scope: %i[mailers notify_account_updated])
    @content = t(:content, scope: %i[mailers notify_account_updated],
                           count: communities_names.length,
                           community_name: communities_names.join(', '))
    @account_args = account_args
    destination = @testing_email || 'facturacion@comunidadfeliz.cl'
    origin = @testing_email || Constants::Email::ADDRESS[:finance]
    cc = contact_emails
    subject = @title
    mail(to: destination, subject: subject, from: origin, cc: cc) do |format|
      format.html
      format.text
    end
  end

  def notify_admin(community_id:, community_name:, content:, user_id:, subject:, user_name:,
                   community_love_messages:)
    @user = User.find_by(id: user_id)
    @community = Community.find_by(id: community_id)
    bcc = @user.crm_email if @user
    @user_name = user_name
    @community_name = community_name

    @title = t(:title, scope: %i[mailers notify_admin])
    @subtitle = content

    destination = @testing_email || 'contacto@comunidadfeliz.com'
    origin = @testing_email || 'antti.kulppi@comunidadfeliz.com'

    unless subject.present?
      subject = t(:subject, scope: %i[mailers notify_admin], user_id: @user.id,
                  user_name: user_name)
    end

    return if @community&.demo.present?

    mail(to: destination, bcc: bcc.to_s, subject: subject, from: origin) do |format|
      format.html
      format.text
    end
  end

  def notify_admin_invoice_irs_billed(invoices_ids:, invoice_lines_data:)
    @invoices = Invoice.includes(:invoice_lines, :invoice_payments).where(
      id: invoices_ids
    ).references(:invoice_payment)
    @title = t(:title, scope: %i[mailers notify_admin_invoice_irs_billed])
    @invoice_lines_data = invoice_lines_data
    destination = @testing_email || Constants::Email::ADDRESS[:finance]
    origin = @testing_email || 'contacto@comunidadfeliz.com'
    cc_mail = @testing_email || Constants::Email::ADDRESS[:finance]
    irs_billed_invoices = @invoices.to_a.count(&:irs_billed)

    subject = t(:subject, scope:               %i[mailers notify_admin_invoice_irs_billed],
                          invoices_length:     @invoices.length - irs_billed_invoices,
                          irs_billed_invoices: irs_billed_invoices)

    mail(to: destination, subject: subject, from: origin, cc: cc_mail) do |format|
      format.html
      format.text
    end
  end

  def notify_admin_invoice_paid(user_to_s:, user_id:, payment_type:, object_url:)
    @object_url = object_url
    @user_to_s = user_to_s
    @title = t(:title, scope: %i[mailers notify_admin_invoice_paid])
    destination = Constants::Email::ADDRESS[:contact]
    origin = Constants::Email::ADDRESS[:contact]
    subject = t(:subject, scope: %i[mailers notify_admin_invoice_paid],
                payment_type: payment_type, user_id: user_id, user_to_s: user_to_s)
    mail(to: destination, subject: subject, from: origin) do |format|
      format.html
      format.text
    end
  end

  def notify_admin_message(email_to:, community_id:, content:, title:, subject:, community_love_messages:, bcc_mail:, user_id:)
    @user = User.find_by(id: user_id)
    @email_to = @testing_email || email_to
    @community = Community.find_by(id: community_id)
    @content = content
    @title = title
    @subject = subject
    @recipient_id = @user&.id
    @recipient_type = @user&.class

    return if @community&.demo.present?

    mail(to: @email_to, subject: subject, from: @from) do |format|
      format.html
      format.text
    end
  end

  def notify_admin_user_demo(user_demo_email:, user_demo_name:, user_demo_company_name:, content:,
                             subject:, vendor:, timezone:)
    @user_demo_name = user_demo_name
    @user_demo_company_name = user_demo_company_name
    @timezone = timezone
    @user_demo = UserDemo.find_by(email: user_demo_email)
    @vendor = vendor
    cc = @testing_email ? [@testing_email] : ['david.pena@comunidadfeliz.com']
    zappier_email = if @user_demo.rol&.downcase&.include?('administrador')
                      ENV['zappier_email_admin']
                    else
                      ENV['zappier_email_copropietario']
                    end
    cc << zappier_email if @user_demo.request_counter == 1 && zappier_email.present?
    @title = t(:title, scope: %i[mailers notify_admin_user_demo], vendor: @vendor['name'],
                       name: @user_demo.name)
    @subtitle = content
    destination = @testing_email || @vendor['email']
    origin = @testing_email || 'antti.kulppi@comunidadfeliz.com'
    mail(to: destination, subject: subject, from: origin, cc: cc) do |format|
      format.html
      format.text
    end
  end

  def notify_bill(params_helper:)
    params_helper.instance_variables[:campaigns]&.each do |campaign|
      attachments["mailing_banner_#{campaign.id}.png"] = campaign.mailing_banner.read
    end
    params_helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end

    if @template_name == 'notify_employee_salary_payment_summary_by_period'
      @footer_type = FOOTER_TYPE[1]
    elsif @template_name == 'notify_finiquito_generation'
      @footer_type = FOOTER_TYPE[2]
    else # mail to resident
      @contact_phone ||= @community&.contact_phone
      @footer_type = FOOTER_TYPE[0]
    end
  end

  def notify_global_finkok_response(params_helper:)
    params_helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end

    @footer_type = FOOTER_TYPE[0]
  end

  def notify_payment_with_pdf_and_xml(params_helper:)
    params_helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end
    @footer_type = FOOTER_TYPE[0]
  end

  def notify_contact_email(name:, email:, subject:, content:, phone:, rol:)
    @name = name
    @email = email
    @phone = phone
    @rol = rol
    @content = content.to_s
    @subject = subject
    @title = t(:title, scope: %i[mailers notify_contact_email])
    @subtitle = t(:subtitle, scope: %i[mailers notify_contact_email])
    @url = @site_url
    mail(to: @from, subject: "Contacto - #{@name}", from: @from) do |format|
      format.html
      format.text
    end
  end

  def notify_demo_finished(user_id:, community_id:, request_by_user_id:, bcc_mail:,
                           community_love_messages:, user_name:, community_name:)
    @user = User.find_by(id: user_id)
    @community = Community.find_by(id: community_id)
    @user_name = user_name
    @community_name = community_name
    @request_by = User.find_by(id: request_by_user_id)
    bcc = @user.crm_email

    @title = t(:title, scope: %i[mailers notify_demo_finished])
    @subtitle = t(:subtitle, scope: %i[mailers notify_demo_finished])
    subject = t(:subject, scope: %i[mailers notify_demo_finished], user_name: @user_name)

    if @request_by.present?
      destination = @request_by.email
      origin = @request_by.crm_email
    else
      destination = 'contacto@comunidadfeliz.com'
      origin = 'antti.kulppi@comunidadfeliz.com'
    end

    email_to = @testing_email || destination
    email_from = @testing_email || origin
    email_bcc = @testing_email || bcc.to_s
    mail(to: email_to, bcc: email_bcc, subject: subject, from: email_from) do |format|
      format.html
      format.text
    end
  end

  def notify_happy_seal_more_info(community_ids:, user_id:)
    @communities = Community.find(community_ids)
    @user = User.find(user_id)
    @title = I18n.t('mailers.notify_happy_seal_more_info.title')
    @subtitle = ''

    names = @communities.pluck(:name)

    @content = I18n.t('mailers.notify_happy_seal_more_info.content',
                      count: names.length,
                      community_name: names.join(', '))
    destination = @testing_email || 'contacto@administradoreschile.cl'
    origin = @testing_email || 'contacto@comunidadfeliz.com'

    subject = @title
    mail(to: destination, subject: subject, from: origin, cc: @user.email) do |format|
      format.html
      format.text
    end
  end

  def notify_new_superadmin(user_id:, password:)
    @user = User.find_by(id: user_id)
    @subject = t(:subject, scope: %i[mailers notify_new_superadmin])

    @recipient_id = @user.id

    @title = t(:title, scope: %i[mailers notify_new_superadmin], user_name: @user.first_name)
    @content = t(:content, scope: %i[mailers notify_new_superadmin], user_name: @user.first_name, user_email: @user.email, user_password: password)
    @email_to = @user.email

    email_to = @testing_email || @email_to
    email_from = @testing_email || @email_from

    mail(to: email_to, subject: @subject, from: email_from) do |format|
      format.html
      format.text
    end
  end

  def notify_invoice_payment_transference_validation(bcc_mail:, community_love_messages:,
                                                     invoice_payment_data:, invoices_data:,
                                                     invoices_ids:, invoices_url:)
    @title = t(:title, scope: %i[mailers notify_invoice_payment_transference_validation])
    @subtitle = t(:subtitle, scope: %i[mailers notify_invoice_payment_transference_validation])

    @content = t(:content, scope: %i[mailers notify_invoice_payment_transference_validation])
    @invoices = Invoice.where(id: invoices_ids).includes(:invoice_lines)
    @invoice_payment_data = invoice_payment_data
    @invoices_data = invoices_data
    @invoices_url = invoices_url

    destination = Constants::Email::ADDRESS[:contact]
    origin = Constants::Email::ADDRESS[:finance]
    cc_email = invoice_payment_data['destination_emails']

    subject = t(:subject, scope: %i[mailers notify_invoice_payment_transference_validation])

    selected_invoices = @invoices.select { |i| i.pdf.present? }
    @files = selected_invoices.each_with_object({}) { |a, hash|
      hash[a.pdf.filename] = a.pdf.read
    }
    @files.each { |name, file| attachments[name] = file }

    if @invoice_payment_data['finkok_complements_ids']
      @finkok_complements = FinkokResponse.where(id: @invoice_payment_data['finkok_complements_ids'])
      @finkok_complements.each do |finkok_complement|
        attachments["#{finkok_complement.uuid}.xml"] = finkok_complement.xml
      end
    end

    mail(to: destination, subject: subject, from: origin, cc: cc_email) do |format|
      format.html
      format.text
    end
  end

  def notify_pdf_payment_receipts(user_id:, user_first_name:, period_expense_id:, period_expense_name:,
                                  public_url:, bcc_mail:, community_name:)
    @period_expense = PeriodExpense.find_by(id: period_expense_id)
    @community = @period_expense.community
    @user = User.find_by(id: user_id)
    @subject = t(:subject, scope: %i[mailers notify_pdf_payment_receipts],
                           community_name: community_name, period_expense_name: period_expense_name)

    @recipient_id = @user.id

    @admin_first_name = user_first_name
    @content_1 = t(:content_1, scope: %i[mailers notify_pdf_payment_receipts])
    @content_2 = t(:content_2, scope: %i[mailers notify_pdf_payment_receipts])

    @btn_download = t(:btn_download, scope: %i[mailers notify_pdf_payment_receipts])
    @email_to = @user.email
    @footer_type = FOOTER_TYPE[2]

    @public_url = public_url # Depends on expiring url from route in Web, the change into residents url is not needed

    email_to = @testing_email || @email_to
    email_from = @testing_email || @email_from
    premailer(
      mail(to: email_to, subject: @subject, from: email_from) do |format|
        format.html { render layout: 'mailer' }
        format.text
      end
    )
  end

  def notify_pending_invoices(account_id:, invoices_ids:, user_emails:, invoices_data:, total:,
                              billing_url:, mail_message:, subject:)

    @account = Account.find_by(id: account_id)
    I18n.locale = "es-#{@account.country_code}"
    @billing_url = billing_url
    @invoices = @account.invoices.includes(:invoice_lines).where(id: invoices_ids)
    @show_invoice_column = @invoices.any?(&:irs_bill_id)
    @colspan_table = @show_invoice_column ? 3 : 2
    @mail_message = mail_message
    @title = t(:title, scope: %i[mailers notify_pending_invoices])
    @invoices_data = invoices_data
    @total = total
    @subtitle = t(:subtitle, scope: %i[mailers notify_pending_invoices])
    destination = @testing_email || user_emails.join(',')
    origin = @testing_email || 'finanzas@comunidadfeliz.com'

    @billing_locals = {
      invoices:      @invoices,
      invoices_data: @invoices_data,
      total:         @total
    }

    premailer(
      mail(to: destination, subject: subject, from: origin) do |format| # TODO: add destination
        format.html
        format.text
      end
    )
  end

  def notify_product_receipt_pdf(params_helper:)
    params_helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end
    return unless @recipient_mail.present? || @send_bcc
  end

  def notify_admin_product_receipt(recipient_name:, recipient_mail:, user_mail:, user_name:, payment_price:, community_id:, property_name:, period_expense:, admin_reminder:, subject:, content:, locale:, paid_at:)
    @locale = locale
    @title = "Estimado(a) #{recipient_name}"
    @subtitle = 'Gracias por preferir ComunidadFeliz'
    @origin_mail = 'ayuda@comunidadfeliz.cl'
    @user_mail = user_mail
    @user_name = user_name
    contact_email = @testing_email || 'notificaciones@mail.comunidadfeliz.com'
    @community = Community.find_by(id: community_id)
    @property_name = property_name
    @period_expense = period_expense
    @admin_reminder = admin_reminder
    @content = content
    @payment_price = payment_price
    @paid_at = Date.parse(paid_at)
    @footer_type = :cf_to_admin

    mail_params = { to: recipient_mail, bcc: false, from: contact_email, subject: subject, template_path: 'user_mailer', template_name: 'notify_admin_product' }
    premailer(
      mail(mail_params) do |format|
        format.html { render 'notify_admin_product', layout: 'mailer' }
        format.text
      end
    )
  end

  def notify_close_common_expense(params_helper:)
    params_helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end
    @footer_type = FOOTER_TYPE[2]
  end

  def notify_renewal_subscription(recipient_name:, recipient_mail:, community_id:, property_name:, subject:, content:, locale:)
    @locale = locale
    @title = t(:title, scope: %i[mailers notify_renewal_subscription], recipient_name: recipient_name.to_s)
    @subtitle = t(:subtitle, scope: %i[mailers notify_renewal_subscription])
    @origin_mail = t(:origin_mail, scope: %i[mailers notify_renewal_subscription])
    @community = Community.find_by(id: community_id)
    @property_name = property_name
    @content = content
    contact_email = 'notificaciones@mail.comunidadfeliz.com'

    mail(to: recipient_mail, bcc: false, from: contact_email,  subject: subject, template_path: 'user_mailer', template_name: 'notify_renewal_subscription')
  end

  def notify_canceled_subscription(recipient_name:, recipient_mail:, community_id:, property_name:, subject:, content:, locale:)
    @locale = locale
    @title = t(:title, scope: %i[mailers notify_canceled_subscription], recipient_name: recipient_name.to_s)
    @subtitle = t(:subtitle, scope: %i[mailers notify_canceled_subscription])
    @origin_mail = t(:origin_mail, scope: %i[mailers notify_canceled_subscription])
    @community = Community.find_by(id: community_id)
    @property_name = property_name
    @content = content
    contact_email = 'notificaciones@mail.comunidadfeliz.com'

    mail(to: recipient_mail, bcc: false, from: contact_email,  subject: subject, template_path: 'user_mailer', template_name: 'notify_canceled_subscription')
  end

  def notify_success_payment(recipient_name:, recipient_mail:, community_id:, property_name:, period_expense:, subject:, payment_price:, locale:)
    @locale = locale
    @title = t(:title, scope: %i[mailers notify_success_payment], recipient_name: recipient_name.to_s)
    @subtitle = t(:subtitle, scope: %i[mailers notify_success_payment])
    @origin_mail = t(:origin_mail, scope: %i[mailers notify_success_payment])
    @community = Community.find_by(id: community_id)
    @property_name = property_name
    @period_expense = period_expense
    @payment_price = payment_price
    contact_email = 'notificaciones@mail.comunidadfeliz.com'

    mail(to: recipient_mail, bcc: false, from: contact_email,  subject: subject, template_path: 'user_mailer', template_name: 'notify_success_payment')
  end

  def notify_feedback(user_name:, email:)
    @url = @site_url
    @title = t(:title, scope: %i[mailers feedback], user_name: user_name.to_s)
    @subtitle = t(:subtitle, scope: %i[mailers feedback])
    @content = t(:content, scope: %i[mailers feedback])
    email_to = @testing_email || email
    mail(to: email_to, subject: 'Contacto', from: @from) do |format|
      format.html
      format.text
    end
  end

  def notify_first_password(admin_name:, community_id:, community_name:, token:, unsubscribe_token:,
                            user_id:, user_name:, bcc_mail:, community_love_messages:)
    @user = User.find_by(id: user_id)
    @admin_name = admin_name
    @token = token
    @community = Community.find_by(id: community_id)
    @community_name = community_name
    @url = @site_url + '/change_password/' + @token
    @title = t(:title, scope: %i[mailers defaults], user_name: user_name)

    @recipient_id = @user.id
    configure_password = t(:configure_password, scope: %i[mailers notify_first_password])
    common_expenses = t(:common_expenses, scope: %i[mailers notify_first_password])
    @subject = "#{configure_password} - #{common_expenses}"
    @email_to = @user.email
    @mail_type = OutgoingMail.mail_types[:first_password]
    @unsubscribe_token = unsubscribe_token
  end

  def notify_user_administrator(user_id:, user_name:, community_id:, community_name:, content:,
                                subject:, bcc_mail:, community_love_messages:)
    @user = User.find_by(id: user_id)
    @community = Community.find_by(id: community_id)
    # bcc = @user.crm_email if @user

    @title = t(:title, scope: %i[mailers notify_user_administrator], user_name: user_name)
    @subtitle = t(:subtitle, scope:          %i[mailers notify_user_administrator],
                             community_name: community_name)
    @content = content

    @recipient_id = @user.id

    @subject = if subject.present?
      t(:subject, scope:          %i[mailers notify_user_administrator],
                             community_name: community_name)
    else
      subject
               end
    @email_to = @user.email
    @mail_type = OutgoingMail.mail_types[:notify_user_administrator]

    @skip = @community&.demo.present?
  end

  def notify_property_fine(community_id:, count:, formatted_price:, property_fine_id:, user_id:,
                           bcc_mail:, community_love_messages:)
    @property_fine = PropertyFine.find_by(id: property_fine_id)
    @count = count
    @user = User.find_by(id: user_id)
    @formatted_price = formatted_price
    @title = t(:title, scope: %i[mailers defaults], user_name: @user.first_name || @user.email)
    @recipient_id = user_id
    @community = Community.find_by(id: community_id)
    @subject =  t(:subject, scope:          %i[mailers notify_property_fine],
                            community_name: @community.name)
    @email_to = @user.email
    @mail_type = OutgoingMail.mail_types[:property_fine]
    @skip = @community&.demo.present?
  end

  def notify_irs_billed(params_helper:)
    params_helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end

    params_helper.attachments.each do |key, value|
      attachments[key] = value
    end

    @invoice_period = @period&.split(";")[0..2].join(",")
    @colspan_table = @invoice_period.blank? ? 3 : 2

    premailer(
      mail(to: @email_to, subject: @subject, from: @email_from) do |format|
        format.html
        format.text
      end
    )
  end

  def notify_undo_payments_excel(user_id:, user_name:, community_id:, community_name:,
                                 result_array:, bcc_mail:, community_love_messages:)
    current_user = User.find_by(id: user_id)
    @recipient_id = current_user.id
    @community = Community.find_by(id: community_id)
    @title = t(:title, scope: %i[mailers undo_payment_excel], user_name: user_name)
    @mail_type = OutgoingMail.mail_types[:notify_undo_payment]
    @email_to = current_user.email
    @subject = t(:subject, scope: %i[mailers undo_payment_excel], community: community_name)
    @origin_mail = @community.contact_email
    @result_array = result_array
  end

  # TODO: remove notify_user_event template after migrating this email to Sendgrid logic
  def notify_user_event_created(admin_email:, common_space_name:, community_id:, community_name:,
                                event:, event_property_name:, recipient_id:, user_name:, bcc_mail:,
                                community_love_messages:)
    @user = User.find_by(id: recipient_id)
    @community = Community.find_by(id: community_id)
    @event = event
    @title = t(:title, scope: %i[mailers defaults], user_name: user_name)
    @content = t(:content, scope: %i[mailers notify_create_event])
    @subcontent = t(:subcontent, scope: %i[mailers notify_create_event])

    @recipient_id = recipient_id
    @subject = t(:subject, scope: %i[mailers notify_create_event], community_name: community_name)
    @email_to = @user&.email || @community&.contact_email
    @origin_mail = admin_email
    @mail_type = OutgoingMail.mail_types[:notify_user_event]
    @template_path = 'user_mailer'
    @template_name = 'notify_user_event'
    @event_property_name = event_property_name
    @common_space_name = common_space_name

    @skip = @community&.demo.present?
  end

  def notify_user_with_pdf_as_attachment(helper:, **_extras)
    helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end
  end

  # only used by notify_creator_report_sent
  def mail_with_pdf_as_attachment(recipient_id:, community_id:, content:,
                                  title:, origin_mail: nil, file_name:, community_love_messages:,
                                  file:, template: 'send_with_attachment', locale: 'es',
                                  subject: nil, subtitle: nil)
    @locale = locale
    @user = User.find(recipient_id)
    @community = Community.find(community_id)
    @content = content
    @title = title
    @recipient_id = @user.id
    @recipient_type = @user.class
    @subject = subject.nil? ? "[ComunidadFeliz] #{title}" : "[#{@community.name}] #{subject}"
    @email_to = @user.email
    @subtitle = subtitle
    @origin_mail = origin_mail || @community.contact_email
    @mail_type = OutgoingMail.mail_types[:send_with_attachment]
    @template_path = 'user_mailer'
    @template_name = template

    @file = file
    @file_name = file_name
  end

  def notify_welcome(user_data:, token:)
    @title = t(:title, scope: %i[mailers welcome], user_name: user_data['first_name'])
    @subtitle = t(:subtitle, scope: %i[mailers welcome])
    @url = @site_url + "/activate/#{token}" # We keep the old url due to the session logic staying in the rails web app
    email_to = @testing_email || user_data['email']
    mail(to: email_to, subject: t(:subject, scope: %i[mailers notify_welcome]), from: @from) do |format|
      format.html
      format.text
    end
  end

  def notify_recover_password(user_id:, token:, new_user:, subject:, community_id:,
                              community_love_messages:)
    @user = User.find_by(id: user_id)
    @url = "#{@site_url}/change_password/#{token}" # We keep the old url due to the session logic staying in the rails web app
    @new_user = new_user
    @title = t(:title, scope: %i[mailers defaults], user_name: @user.first_name)
    @subject = subject
    @recipient_id = @user.id
    @community = @community_id.blank? ? nil : Community.find_by(id: community_id)
    @mail_type = OutgoingMail.mail_types[:notify_recover_password]
    @email_to = @user.email
    @subtitle = t(:subtitle, scope: %i[mailers notify_recover_password]) if @new_user
  end

  def notify_employee_salary_payment_summary(params_helper:)
    params_helper.instance_variables.each do |name, value|
      instance_variable_set("@#{name}", value)
    end
    @footer_type = FOOTER_TYPE[1]
  end

  def notify_email_confirmation(user_id:, token:, subject:, community_id:)
    @user = User.find_by(id: user_id)
    @url = "#{@site_url}/email_confirmation/#{token}/#{community_id}"
    @title = t(:title, scope: %i[mailers defaults], user_name: @user.first_name)
    @subject = subject
    @recipient_id = @user.id
    @community = @community_id.blank? ? nil : Community.find_by(id: community_id)
    @mail_type = OutgoingMail.mail_types[:notify_email_confirmation]
    @email_to = @user.validate_email
    @subtitle = t(:subtitle, scope: %i[mailers notify_email_confirmation])
  end

  def notify_importation_complete(file_id:, content:, subject:, warnings:)
    @excel_file = ExcelUpload.find_by(id: file_id)
    @excel_file_name = @excel_file.excel.filename
    @excel_file_date = @excel_file.created_at
    @footer_type = FOOTER_TYPE[2]
    @user = @excel_file.user
    @warnings = warnings
    @community = @excel_file.community
    @content = content
    @email_to = @user.email
    @subject = subject
  end

  def notify_purchase_through_upselling(community_id:, module_name:, package_price:, package_currency:, purchased_at:)
    @module_name = module_name
    @package_price = package_price
    @package_currency = package_currency
    @purchased_at = purchased_at
    @community = Community.find(community_id)
    @title = t(:title, scope: %i[mailers notify_purchase_through_upselling])
    destination = @testing_email || [Constants::Email::ADDRESS[:finance], 'feliz@comunidadfeliz.com']
    origin = @testing_email || 'notificaciones@mail.comunidadfeliz.com'
    subject = I18n.t(:subject, scope: %i[mailers notify_purchase_through_upselling],
                     community:   @community.name,
                     module_name: @module_name)
    mail(to: destination, subject: subject, from: origin) do |format|
      format.html
      format.text
    end
  end

  def notify_transfers_excel(user_id:, user_name:, community_id:, file_url:, file_name:)
    current_user = User.find_by(id: user_id)
    @recipient_id = user_id
    @recipient_name = user_name
    @community = Community.find_by(id: community_id)
    @file_name = file_name
    @file = Net::HTTP.get(URI.parse(file_url))
    @mail_type = OutgoingMail.mail_types[:notify_transfers_excel]
    @email_to = current_user.email
    @subject = t('mailers.notify_transfers_excel.subject', community: @community.name)
    @origin_mail = @community.contact_email
    @footer_type = FOOTER_TYPE[2]
  end

  def notify_admin_block_date_postponed(account_id:, user_emails:)
    @account = Account.find_by(id: account_id)
    @email_to = user_emails.join(',')
    byebug
    @email_from = @testing_email || @billing_email
    @mail_type = CUSTOM_TEMPLATE_MAIL_TYPES[2]
    @subject = t(:subject, scope: %i[mailers notify_admin_block_date_postponed])
    @footer_type = FOOTER_TYPE[2]
  end

  def notify_leaving_community(leaving_community_id:, billing_url:)
    @leaving_community = LeavingCommunity.preload(:community).find_by(id: leaving_community_id)
    @billing_url = billing_url
    @community = @leaving_community.community
    I18n.locale = "es-#{@community.country_code}"
    @title = t('mailers.notify_leaving_community.title')
    subject = t('mailers.notify_leaving_community.subject')
    destination = @testing_email || @community.contact_email
    origin = @testing_email || Constants::Email::ADDRESS[:finance]

    mail(to: destination, from: origin, subject: subject) do |format|
      format.html
      format.text
    end
  end

  def notify_about_to_deactivate_community(community_id:, days_before_deactivation:, billing_url:)
    @community = Community.find_by(id: community_id)
    @billing_url = billing_url
    I18n.locale = "es-#{@community.country_code}"
    @days_before_deactivation = days_before_deactivation
    @title = t('mailers.notify_about_to_deactivate_community.title')
    @subtitle = t('mailers.notify_about_to_deactivate_community.subtitle')
    subject = t('mailers.notify_about_to_deactivate_community.subject', days_left: @days_before_deactivation)
    destination = @testing_email || @community.contact_email
    origin = @testing_email || Constants::Email::ADDRESS[:finance]

    mail(to: destination, from: origin, subject: subject) do |format|
      format.html
      format.text
    end
  end

  def notify_leaving_communities_previous_week(leaving_communities_ids:)
    I18n.locale = 'es-CL'
    @leaving_communities = LeavingCommunity.includes(:community).where(id: leaving_communities_ids)
    @title = t('mailers.notify_leaving_communities_previous_week.title')
    subject = t('mailers.notify_leaving_communities_previous_week.subject', from: 1.week.ago.strftime('%d/%m/%Y'), to: Time.zone.today.strftime('%d/%m/%Y'))
    destination = @testing_email || Constants::Email::ADDRESS[:finance]
    origin = @testing_email || Constants::Email::ADDRESS[:finance]

    mail(to: destination, from: origin, subject: subject) do |format|
      format.html
      format.text
    end
  end

  private

  def premailer(mail)
    options = { with_html_string: true, input_encoding: 'utf-8' }

    mail.text_part.body = Premailer.new(mail.text_part.body.to_s, **options).to_plain_text
    mail.html_part.body = Premailer.new(mail.html_part.body.to_s, **options).to_inline_css

    mail
  end

  def set_email_with_redesign
    @mail_with_redesign = true
  end

  def set_from_email
    @email_from = @testing_email || @notifications_from_email
  end

  def send_outgoing_mail
    email_to = @testing_email || @email_to
    email_from = @testing_email || @email_from
    outgoing_mail = OutgoingMail.new(recipient_id:   @recipient_id,
                                     recipient_type: @recipient_type,
                                     origin_id:      @origin_id,
                                     origin_type:    @origin_type,
                                     community_id:   @community&.id,
                                     mail_type:      @mail_type,
                                     subject:        @subject,
                                     email_to:       email_to,
                                     email_from:     email_from)
    outgoing_mail.save unless @community&.id.blank? # Save only if there is community related.

    if !@file.nil? && !@file_name.nil?
      attachments[@file_name] = @file
    elsif !@files.nil? && !@files.empty?
      @files.each { |name, file| attachments[name] = file }
    end

    dummy = ENV['SENDGRID_ENV'] == 'testing' ? true.to_s : false.to_s
    # don't remove this header: is mandatory to check email open/click statuses
    # in SendgridMailer this is sent via custom_args API V3 attribute
    headers['X-SMTPAPI'] = {
      unique_args: {
        mail_id:           outgoing_mail&.id,
        community_api_key: @community&.community_sendgrid_key,
        dummy:             dummy
      }
    }.to_json

    bcc = if @bcc_mail == 1 && @mail_type == OutgoingMail.mail_types[:send_with_attachment]
            [@community&.bcc_email.to_s]
          else
            []
          end

    mail_params = { to: email_to, subject: @subject, from: email_from }
    mail_params[:reply_to] = @origin_mail if @origin_mail.present?
    layout = 'mailer' if @mail_with_redesign

    mail = if uses_custom_template?(@mail_type)
             mail_params.merge!(template_path: @template_path, template_name: @template_name, bcc: [bcc])

             mail(mail_params) do |format|
               format.html { render @template_name, layout: layout }
               format.text { render @template_name }
             end
           else
             mail(mail_params) do |format|
               format.html { render layout: layout }
               format.text
             end
           end

    premailer(mail)
  end

  def attach_xml
    attachments["#{File.basename(@file_name, '.*')}.xml"] = {
      mime_type: 'application/xml',
      content: @xml
    }
  end

  def uses_custom_template?(mail_type)
    CUSTOM_TEMPLATE_MAIL_TYPES.include? mail_type
  end
end
