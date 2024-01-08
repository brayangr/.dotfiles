# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                                 :integer          not null, primary key
#  accepted_terms_and_conditions      :boolean          default(FALSE)
#  active                             :boolean          default(TRUE)
#  admin                              :boolean          default(FALSE)
#  admin_tour_seen                    :boolean          default(FALSE)
#  available_until                    :date
#  avatar                             :string
#  avatar_updated_at                  :datetime
#  country_code                       :string           default("CL")
#  created_by_oauth                   :boolean          default(FALSE)
#  crm_email                          :string           default("comunidadfeliz@pipedrivemail.com")
#  customer_number                    :integer
#  deleted                            :boolean          default(FALSE)
#  demo                               :boolean          default(FALSE)
#  demo_start                         :date
#  email                              :string
#  fcm_registration_token             :string
#  first_login                        :boolean          default(TRUE)
#  first_name                         :string
#  identity_document_back             :string
#  identity_document_back_updated_at  :datetime
#  identity_document_front            :string
#  identity_document_front_updated_at :datetime
#  image                              :string
#  importer_type                      :string
#  last_mobile_sign_in_at             :datetime
#  last_name                          :string
#  last_notification_date             :date             default(Wed, 30 Sep 2020)
#  last_online_payment_by_app         :datetime
#  last_sign_in_at                    :datetime
#  metadata                           :jsonb
#  mfa_active                         :boolean          default(FALSE)
#  mfa_enabled                        :boolean          default(FALSE)
#  mfa_last_updated_at                :date
#  mfa_secret                         :string
#  mobile_sign_in_count               :integer          default(0)
#  mother_last_name                   :string
#  need_to_accept_conditions          :boolean          default(FALSE)
#  new_interface                      :boolean          default(FALSE)
#  number_notifications               :integer          default(0)
#  opt_in_email_campaign              :boolean          default(TRUE), not null
#  paid_online_by_app                 :boolean          default(FALSE)
#  password_hash                      :string
#  password_salt                      :string
#  payments_terms_conditions_date     :datetime
#  phone                              :string
#  rut                                :string
#  sign_in_count                      :integer          default(0)
#  slug                               :string
#  try_login                          :integer          default(0)
#  unknown_user                       :boolean          default(FALSE)
#  validate_email                     :string
#  validated                          :boolean          default(FALSE)
#  created_at                         :datetime
#  updated_at                         :datetime
#  excel_upload_id                    :integer
#  importer_id                        :integer
#  real_estate_agency_id              :integer
#  server_user_group_id               :integer
#
# Indexes
#
#  index_users_on_customer_number                (customer_number) UNIQUE
#  index_users_on_email                          (email)
#  index_users_on_importer_type_and_importer_id  (importer_type,importer_id)
#  index_users_on_slug                           (slug) UNIQUE
#
class User < ApplicationRecord
  include ObjectActions::ObjectActionHelper
  include Importable
  include ApiFileUploadHelper
  include AttachmentTimerUpdater
  extend Searchable
  COMMON_PICTURE_EXTENSION = 'jpg'

  acts_as_google_authenticated(issuer: 'ComunidadFeliz', lookup_token: :email, google_secret_column: :mfa_secret)

  attr_accessor :password, :current_password, :password_confirmation, :old_email, :current_user, :massively_imported
  attr_reader :current_community_id, :current_user_id
  has_many   :account_summary_sheets
  has_many   :admin_community_users, -> { where(role_code: CommunityUser.reversed_roles('Administrador'), active: true) }, class_name: 'CommunityUser'
  has_many   :advertisement_users
  has_many   :advertisements_user_actives, -> { where('advertisement_users.active  = ?', true).includes(:advertisement, :user) }, class_name: 'AdvertisementUser'
  has_many   :advertisements_user_enables, -> { where("(NOW()::date >= (advertisement_users.last_viewed::date + (interval '1 day'*advertisements.days_without_show)) OR advertisement_users.last_viewed IS NULL) AND advertisements.active = ? AND advertisement_users.active  = ?", true, true).includes(:advertisement, :user).references(:advertisements, :advertisement_users) }, class_name: 'AdvertisementUser'
  has_many   :advertisements_user_inactives, -> { where('advertisement_users.active  = ?', false).includes(:advertisement, :user) }, class_name: 'AdvertisementUser'
  has_many   :all_property_users, class_name: 'PropertyUser'
  has_many   :answers
  has_many   :attendant_community_users, -> { where(role_code: CommunityUser.reversed_roles('Encargado'), active: true) }, class_name: 'CommunityUser'
  has_many   :api_tokens, dependent: :delete_all
  has_many   :bundle_payments
  has_one    :client_user_user
  has_many   :committee_community_users, -> { where(role_code: CommunityUser.reversed_roles('Directiva'), active: true) }, class_name: 'CommunityUser', dependent: :destroy
  has_many   :community_users, -> { where(active: true) }
  has_many   :community_users_with_at_least_3_months, -> { joins(:community).where(role_code: CommunityUser.reversed_roles('Administrador'), active: true).where(CommunityUser.arel_table[:created_at].lteq(Date.today - 3.months)).merge(Community.active_and_count) }, class_name: 'CommunityUser'
  has_many   :events, -> { where(active: true) }, foreign_key: :reservation_user_id
  belongs_to :excel_upload, foreign_key: 'importer_id', inverse_of: :users,
                            class_name: 'ExcelUpload', optional: true
  has_one    :fiscal_identification, as: :fiscal_identifiable, dependent: :destroy
  has_many   :identifications, as: :identificable, dependent: :destroy
  has_many   :inactive_property_users, -> { where(active: false) }, class_name: 'PropertyUser'
  has_many   :invoice_payments
  has_many   :issues, -> { active }, foreign_key: :user_in_charge_id
  has_many   :leaving_communities
  has_many   :logs
  has_one    :main_client_user, class_name: 'ClientUser', foreign_key: 'main_user_id'
  has_many   :manageable_community_users, -> { where(role_code: CommunityUser.reversed_roles.values_at('Administrador', 'Encargado', 'Directiva'), active: true) }, class_name: 'CommunityUser'
  has_many   :manager_community_users, -> { where(role_code: CommunityUser.reversed_roles.values_at('Encargado', 'Directiva'), active: true) }, class_name: 'CommunityUser'
  has_many   :notification_user_logs
  has_many   :previous_manageable_community_users, -> { where(role_code: CommunityUser.reversed_roles.values_at('Administrador', 'Encargado', 'Directiva'), active: false) }, class_name: 'CommunityUser'
  has_many   :outgoing_mails, class_name: 'OutgoingMail', foreign_key: :recipient_id
  has_many   :owned_bundle_payments, class_name: 'BundlePayment', foreign_key: 'owner_id'
  has_many   :posts, -> { where('published = ? and active  = ?', true, true) }
  has_many   :property_users, -> { where(active: true) }, dependent: :destroy
  has_many   :property_user_requests, -> { where(active: true) }
  has_many   :pending_property_user_requests, -> { where(active: true, confirmed: false) }, class_name: 'PropertyUserRequest'
  belongs_to :real_estate_agency, optional: true
  has_many   :tokens
  has_many   :unconfirmed_property_user_requests, -> { where(active: true).where.not(confirmed: true) }, class_name: 'PropertyUserRequest'
  has_many   :unified_property_users, -> { where('property_users.grouped_bills = ? and property_users.active = ?', true, true) }, class_name: 'PropertyUser'
  has_many   :unpublished_posts, -> { where('published = ? and active  = ?', false, true) }, class_name: 'Post'
  has_many   :user_oauths, dependent: :destroy
  has_many   :user_read_posts
  has_many   :user_read_surveys
  has_many   :tours

  # Through associations
  has_many   :admin_communities, -> { where('communities.active = ?', true) }, through: :admin_community_users, source: :community
  has_many   :advertisements, through: :advertisement_users
  has_many   :advertisements_actives, -> { where('advertisements.active = ?', true).includes(:advertisement_users).references(:advertisements, :advertisement_users) }, through: :advertisement_users, source: :advertisement, class_name: 'Advertisement'
  has_many   :all_properties, through: :all_property_users, class_name: 'Property', source: :property # NO CAMBIAR POR SYMBOLS!! hasta tener Rails 5
  has_many   :attendant_communities, -> { where(communities: { active: true }) }, through: :attendant_community_users, source: :community
  has_many   :current_properties, -> { where('properties.active = ?', true) }, through: :property_users, class_name: 'Property', source: :property
  has_one    :client_user, through: :client_user_user
  has_many   :committee_communities, -> { where(communities: { active: true }) }, through: :committee_community_users, source: :community
  has_many   :distinct_manageable_communities, -> { where(active: true).distinct }, through: :manageable_community_users, source: :community
  has_many   :manageable_communities, -> { where(active: true) }, through: :manageable_community_users, source: :community
  has_many   :manager_communities, -> { where(communities: { active: true }) }, through: :manager_community_users, source: :community
  has_many   :previous_manageable_communities, through: :previous_manageable_community_users, source: :community
  has_many   :properties, -> { joins(accessible_community: :enabled_users_setting).where('properties.active = ?', true) }, through: :property_users, class_name: 'Property', source: :property # NO CAMBIAR POR SYMBOLS!! hasta tener Rails 5 ##
  has_many   :real_estate_agency_communities, through: :real_estate_agency, source: :communities
  has_many   :related_users, through: :main_client_user, source: :users
  has_many   :unified_properties, through: :unified_property_users, source: :property

  # Dependant through associations
  has_many   :accounts, through: :admin_communities, source: :accounts
  has_many   :black_list_guests, through: :properties
  has_many   :client_communities, -> { active_and_count }, through: :related_users, source: :admin_communities
  has_many   :distinct_communities, -> { accessible.distinct }, through: :properties, source: :community
  has_many   :communities, -> { accessible }, through: :properties
  has_many   :previous_properties, through: :inactive_property_users, source: :property
  has_many   :previous_communities, through: :previous_properties, source: :community
  has_many   :communities_history, through: :all_properties, source: :community
  has_many   :invoices, -> { where(active: true, nullified: false) }, through: :accounts
  has_many   :unpaid_invoices, -> { where(active: true, paid: false, nullified: false).includes(invoice_lines: %i[community pricing]) }, class_name: 'Invoice', through: :accounts
  has_many   :surveys, through: :communities
  belongs_to :server_user_group, optional: true
  has_one    :server, through: :server_user_group
  has_one :particular_address, class_name: 'Address', as: :addressable, dependent: :destroy, inverse_of: :addressable
  has_many   :profiles, dependent: :destroy

  scope      :active, -> { where(active: true) }
  scope      :first_two_users_not_in_charge, ->(user_id:) { where.not(id: user_id).first(2) }
  scope      :with_valid_email, -> { where.not(email: ['', nil]).where("email LIKE '%_@__%.__%'") }
  scope      :without_profiles, -> { left_outer_joins(:profiles).where(profiles: { id: nil }) }

  accepts_nested_attributes_for :community_users
  accepts_nested_attributes_for :identifications, allow_destroy: true, reject_if: proc { |attributes| attributes['identificable_id'].blank? }
  accepts_nested_attributes_for :fiscal_identification, allow_destroy: true
  accepts_nested_attributes_for :particular_address

  searchable_attributes :first_name, :last_name, :email, :rut, :id

  before_save :encrypt_password, :verify_phone_and_email, :verify_identity_type
  before_validation { email.try(:downcase!) }
  after_save :log_changes
  before_destroy :validate_destroy
  # API
  has_one :api_key
  # END API
  validates_confirmation_of :password
  validates_presence_of :password, on: :create
  validates_length_of :password, minimum: 4, allow_blank: true
  validate :password_complexity, if: -> { admin && password.present? }

  validates :email, uniqueness: { allow_blank: true }, unless: :massively_imported
  validates_presence_of :email, on: :update, if: -> { @current_user&.id == id }
  validate :email_change, on: :update
  # Only 1 unknown_user at all times
  validates :unknown_user, uniqueness: true, if: :unknown_user
  validates_associated :identifications
  validates_associated :fiscal_identification, if: proc { |user| Constants::FiscalIdentification::INVOICE_READY_COUNTRIES.include?(user.country_code) }
  validates_associated :particular_address

  mount_uploader :avatar, AvatarUploader

  mount_uploader :identity_document_back, PropertyDocumentUploader
  mount_uploader :identity_document_front, PropertyDocumentUploader

  validates_format_of :email, with: URI::MailTo::EMAIL_REGEXP, message: :not_valid, allow_blank: true

  validates :validate_rut, rut: { message: I18n.t('activerecord.errors.commons.rut') }, allow_blank: true, if: :locale_cl?

  # validates :accepted_terms_and_conditions, :acceptance => {:accept => true, :message => "deben ser aceptadas"}

  # Abreviatures ransack to search
  ransack_alias :id_community, :property_users_property_community_id_or_community_users_community_id_or_real_estate_agency_communities_id

  @apple = 'APPLE'.freeze

  before_save :replicate_rut

  before_save :update_notification_date, if: :new_interface_changed?

  delegate :changed?, to: :particular_address, prefix: 'address', allow_nil: true
  delegate :present?, to: :particular_address, prefix: 'address', allow_nil: true
  delegate :direction, to: :particular_address, prefix: false, allow_nil: true

  scope :in_charge_of_community, lambda { |community_id|
    joins(property_users: :property).where(
      properties:     { active: true, community_id: community_id },
      property_users: { in_charge: true }
    )
  }

  scope :available_for_survey_notification, lambda { |args|
    query = self
    query = query.joins(property_users: :property)
      .where.not(email: ['', nil])
      .where(
        properties:     { active: true, community_id: args[:community_id] },
        property_users: { active: true }
      )
      .distinct
    query.where!(property_users: { in_charge: true }) if args[:add_in_charge_filter]
    query
  }

  scope :available_for_survey_push_notification, lambda { |args|
    available_for_survey_notification(args)
      .where.not(fcm_registration_token: ['', nil])
  }

  scope :community_recipients, lambda { |community_id|
    joins(:outgoing_mails).where(
      outgoing_mails: { community_id: community_id }
    )
  }

  scope :without_client, lambda {
    left_outer_joins(:client_user_user).where(
      client_user_users: { id: nil }
    )
  }

  scope :main_users, lambda {
    left_outer_joins(:client_user_user, :main_client_user).where(
      'client_user_users.id IS NULL OR client_users.id IS NOT NULL'
    )
  }

  scope :administrators, lambda {
    joins(:community_users).merge(
      CommunityUser.administrators
    )
  }

  scope :with_active_and_count_communities, lambda {
    joins(community_users: :community).merge(
      Community.active_and_count
    )
  }

  scope :editable, lambda {
    joins(
      "LEFT JOIN community_users
        ON community_users.user_id = users.id
        AND community_users.active
        AND role_code IN (1, 2, 3)"
    ).where(community_users: { id: nil }, admin: false).distinct
  }

  scope :is_manager, lambda { |communities_ids = []|
    query = <<~SQL
      EXISTS (
        SELECT community_users.id FROM community_users
        INNER JOIN communities ON community_users.community_id = communities.id
        WHERE community_users.user_id = users.id AND
              community_users.active = true AND
              (? OR communities.id IN (?))
      )
    SQL
    where(query, communities_ids.empty?, communities_ids)
  }

  scope :has_properties, lambda { |communities_ids = []|
    query = if communities_ids.empty?
      <<~SQL
        EXISTS (
          SELECT id
          FROM property_users
          WHERE user_id = users.id
        )
      SQL
    else
      <<~SQL
        EXISTS (
          SELECT property_users.id FROM property_users
          INNER JOIN properties ON properties.id = property_users.property_id
          WHERE property_users.user_id = users.id AND
                properties.community_id IN (?)
        )
      SQL
    end
    where(query, communities_ids)
  }

  scope :churned_mobile_residents, lambda {
    active
      .with_valid_fcm_registration_token
      .joins(:properties)
      .where(id: Log.from_mobile.not_admin.churned_users_with_last_activity.pluck(:user_id))
      .distinct
  }
  scope :with_valid_fcm_registration_token, -> { where.not(fcm_registration_token: [nil, '']) }

  include CommunitiesHelper
  include Countries

  extend FriendlyId
  friendly_id :slug_candidates, use: %i[slugged finders]

  def tour_empty?(resource_model)
    tours.exist_model(resource_model: resource_model).blank?
  end

  def slug_candidates
    [
      %i[first_name last_name],
      %i[first_name last_name id],
      %i[first_name last_name id created_at_slug]
    ]
  end

  def property_user_validations
    PropertyUserValidation.right_join_property_user.where(property_users: { user: self })
  end

  def replicate_rut
    return unless rut_changed? && country_code == 'CL'

    identifications.find_by(identity_type: 'RUT')&.update(identity: rut)
  end

  def locale_cl?
    locale_to_validate = get_locale(country_code)
    locale_to_validate ||= I18n.locale.to_s
    locale_to_validate == 'es-CL'
  end

  # Verify phone to send SMSs
  def verify_phone_and_email
    self.phone = phone.to_s.delete(' +') if phone.to_s != ''
    self.email = email.to_s.delete(" \t").downcase
  end

  validate :verify_email_uniqueness
  def verify_email_uniqueness
    verify_phone_and_email
  end

  def show_ocs_tutorial_modal?
    metadata['show_ocs_tutorial_modal'] != false
  end

  def validate_destroy
    throw(:abort) if unknown_user
  end

  def current_attributes(community_id: nil, user_id: nil)
    @current_community_id = community_id
    @current_user_id = user_id
  end

  def log_changes
    fields_changed = saved_changes.except!(:created_at, :updated_at).map do |key, values|
      "#{key} (#{values.join(' -> ')})"
    end.join(', ')
    return unless fields_changed.present?

    Log.create(
      value: "Atributos actualizados: [#{fields_changed}]", user_id: @current_user_id,
      community_id: @current_community_id, origin_class: self.class.name, origin_id: id
    )
  end

  def initialize_log_changes(old_user: false, admin: false)
    fields_changed = attributes.except!(:created_at, :updated_at).map do |key, value|
      next unless value.present?

      old_value = nil
      if old_user
        if admin
          next unless %w[first_name last_name mother_last_name email phone country_code rut].include?(key)
        else
          next unless key == 'active'
        end
      end
      "#{key} (#{[old_value, value].join(' -> ')})"
    end.compact.join(', ')
    return unless fields_changed.present?

    Log.new(
      value: "Atributos actualizados: [#{fields_changed}]", user_id: @current_user_id,
      community_id: @current_community_id, origin_class: self.class.name, origin_id: id
    )
  end

  def verify_identity_type
    if identifications.present? && identifications.first.identity_type != get_identity_type
      identifications.first.identity_type = get_identity_type
    end
  end

  #####################################
  ######### Better Attributes #########
  #####################################

  def created_at_slug
    (created_at || Time.now).strftime('%m-%y')
  end

  def to_s(community_id: nil)
    return full_name(community_id: community_id) if community_id.present?

    r = [first_name, last_name, mother_last_name].reject(&:blank?).join(' ')
    r = r.downcase.titleize.strip
    r != '' ? r : email
  end

  def to_i
    id
  end

  def full_name(community_id: nil)
    profile = community_profile(community_id: community_id, cached: profiles_loaded?)

    profile.present? ? profile.to_s : full_name_unformatted.downcase.titleize
  end

  def full_name_unformatted
    ("#{first_name || ''} #{last_name || ''} #{mother_last_name || ''}")
      .split(' ').join(' ')
  end

  # API
  def to_json(_scope = '')
    super(only: %i[id email], methods: %i[full_name access_token])
  end

  def access_token
    self.api_key = api_key || ApiKey.create(user_id: id)
    api_key.access_token
  end
  # END API

  def graphql_token
    payload = { "user-id": id }
    JWT.encode(payload, ENV['JWT_SECRET_KEY'], 'HS256')
  end

  def resident_jwt_token(encode: true, expiration: 5.minutes, path: '/', community_id: nil, property_id: nil)
    # community and property ids criteria extracted from signInUser mutation behaviour
    community_id ||= communities.first&.id
    property_id ||= properties.where(community_id: community_id).first&.id
    payload = {
      id: id.to_s,
      email: email,
      token: graphql_token,
      communityId: community_id,
      propertyId: property_id,
      redirectTo: path,
      profile: 'resident',
      exp: (Time.current.utc + expiration).to_i
    }
    encode ? JWT.encode(payload, ENV['JWT_SECRET_KEY'], 'HS256') : payload
  end

  def name
    to_s
  end

  def rut(community_id: nil)
    object = community_profile(community_id: community_id, cached: profiles_loaded?) || self

    identity_type = Countries.get_identity_type(object.country_code).first
    identity = object.is_a?(User) ? object.identifications.detect { |i| i.identity_type == identity_type }&.identity : object.identification&.identity

    return identity if identity.presence

    read_attribute(:rut)
  end

  def profiles_loaded?
    profiles&.loaded?
  end

  def validate_rut
    self.rut if !self.persisted? || self.rut_changed?
  end

  def get_identity_type
    locale = get_locale(country_code) if id.present?
    locale ||= I18n.locale.to_s
    case locale
    when 'es-CL' then 'RUT'
    when 'es-MX' then 'RFC'
    when 'es-GT' then 'DPI'
    when 'es-SV' then 'DUI'
    when 'es-BO' then 'NIT'
    when 'es-EC' then 'EC'
    when 'es-HN' then 'RTN'
    when 'en-US' then 'SSN'
    when 'es-UY' then 'CI'
    when 'es-PE' then 'DNI'
    when 'es-PA' then 'CIP'
    when 'es-DO' then 'CIE'
    else 'RUT'
    end
  end

  def identity_type
    identity_type = get_identity_type
    identifications.detect { |i| i.identity_type == identity_type }&.identity
  end

  def updates_or_create_indentification(identity)
    user_identification = identifications.find_or_initialize_by(identificable_id: id, identity_type: get_identity_type)
    user_identification.identity = identity
    user_identification.save
    user_identification
  end

  def update_notification_date
    self.last_notification_date = DateTime.now.utc if new_interface
  end

  def get_customer_number
    # Assign client number when requested for the first time
    unless customer_number.present?
      # Using 1000 as starting client number if no user has a number yet
      # self.customer_number = (max = User.maximum(:customer_number)).present? ? (max + 1) : 1000
      # Uniq customer number based on user id
      self.customer_number = id * 7 + Random.rand(7)
      save
    end

    customer_number
  end

  def get_image(size = :medium)
    return avatar.expiring_url(60, size) if avatar?

    return image if image.present?

    CarrierWaveHandler.default_avatar(size: size)
  rescue StandardError
    CarrierWaveHandler.default_avatar(size: size)
  end

  def save_base64_picture(picture_in_base64)
    data_picture_parts = picture_in_base64.match(%r{\Adata:([-\w]+/[-\w\+\.]+)?;base64,(.*)}m) || []
    image_data = data_picture_parts[2]
    ext = MIME::Types[data_picture_parts[1]]&.first&.preferred_extension
    ext ||= COMMON_PICTURE_EXTENSION
    content_type = data_picture_parts[1]
    file_name = "picture.#{ext}"

    unless image_data && content_type
      errors.add :base, I18n.t('activerecord.errors.models.user.attributes.avatar.invalid')
      raise ActiveRecord::RecordInvalid, self
    end

    StringIO.open(Base64.decode64(image_data)) do |data|
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = file_name
      data.content_type = content_type
      self.avatar = data
      save!
    end
  end

  def save_base64_identity_document(base64_back: nil, base64_front: nil, remove_back: false, remove_front: false)
    self.identity_document_back = nil if remove_back
    self.identity_document_front = nil if remove_front

    if base64_back.present?
      self.identity_document_back = extract_file_from_base64_string(base64_back, 'identity_document_back', support_pdf: false)

      return false if identity_document_back.blank?
    end

    if base64_front.present?
      self.identity_document_front = extract_file_from_base64_string(base64_front, 'identity_document_front', support_pdf: false)

      return false if identity_document_front.blank?
    end

    save
  end

  def identity_document_zip_filename
    I18n.t('views.users.identity_document_zip_filename', user_name: full_name.gsub(' ', '_')).transliterate
  end

  def generate_identity_document_zip
    open_uri_max_string = OpenURI::Buffer::StringMax
    OpenURI::Buffer.const_set 'StringMax', 0 # Allow lightweight files to be stored as a Tempfile

    zipfile_name = "#{Rails.root}/public/#{identity_document_zip_filename}.zip"

    documents = {
      front: { url: identity_document_front.download_url },
      back:  { url: identity_document_back.download_url }
    }

    documents.each do |type, attrs|
      documents[type][:file] = URI(attrs[:url]).open if attrs[:url].present?
    end

    File.delete(zipfile_name) if File.exist?(zipfile_name)

    Zip::File.open(zipfile_name, create: true) do |zipfile|
      documents.each do |type, attrs|
        zipfile.add(identity_document_filename(type), attrs[:file]) if attrs[:url].present?
      end
    end

    OpenURI::Buffer.const_set 'StringMax', open_uri_max_string # restore to previous value

    zipfile_name
  end

  def identity_document_filename(document_type)
    document_name = I18n.t("views.property_user_validations.identity_document_filename.#{document_type}")
    user_file_name = full_name.gsub(' ', '')

    document = case document_type
               when :front then identity_document_front
               when :back  then identity_document_back
               end

    "#{document_name}#{user_file_name}.#{document.file.extension}".transliterate
  end

  def any_identity_document_uploaded?
    identity_document_front.download_url.present? || identity_document_back.download_url.present?
  end

  def properties_in_community(community_id)
    properties.where(community_id: community_id)
  end

  def permissions_in_community(community_id)
    community_user = community_users.where(community_id: community_id,
                                           role_code: [CommunityUser.reversed_roles('Directiva'),
                                                       CommunityUser.reversed_roles('Encargado')])
    permissions = Permission.where(community_user: community_user).order(id: :asc)

    # If manager has no permissions in community, create them with value 0
    if community_user.present? && permissions.blank?
      Permission.code_options.each do |code, _option|
        Permission.where(community_user_id: community_user.first.id, code: code).first_or_create(value: 0)
      end
      permissions = Permission.where(community_user: community_user).order(id: :asc)
    end

    permissions
  end

  def all_communities_ids
    all_communities.map(&:id)
  end

  def all_communities
    (communities + manageable_communities + real_estate_agency_communities).uniq
  end

  def all_previous_communities
    (previous_communities + previous_manageable_community_users).uniq
  end

  def all_previous_communities_ids
    all_previous_communities.map(&:id)
  end

  def all_previous_and_current_communities
    (communities_history + manageable_communities + real_estate_agency_communities+ previous_manageable_community_users ).uniq
  end

  def all_previous_and_current_communities_ids
    all_previous_and_current_communities.map(&:id)
  end

  def get_managers(extra_community_id = nil)
    admin_communities = self.admin_communities.pluck(:community_id)
    admin_communities += [extra_community_id] if extra_community_id.present?
    community_user =  CommunityUser.where(community_id: admin_communities, active: true, role_code: CommunityUser.reversed_roles('Encargado'))
    User.where(id: community_user.pluck(:user_id))
  end

  def get_permissions(community_id = nil)
    community_users = community_id.present? ? self.community_users.where(community_id: community_id) : self.community_users
    Permission.where(community_user_id: community_users.pluck(:id)).order('community_user_id asc')
  end

  def get_permission(community_id, code)
    community_user = attendant_community_users.where(community_id: community_id).first
    if community_user.present?
      Permission.where(community_user_id: community_user.id, code: code).first_or_create(value: 0)
    end
  end

  def get_region
    case country_code
    when 'CL' then 'America/Santiago'
    when 'MX' then 'Mexico/General'
    when 'GT' then 'America/Guatemala'
    when 'SV' then 'America/El_Salvador'
    when 'BO' then 'America/La_Paz'
    else 'America/Santiago'
    end
  end

  # Cantidad de propiedades morosas
  def defaulter_properties
    count = 0
    properties.each do |property|
      bill = property.bills.where(period_expense_id: property.community.last_closed_period_expense.id).first
      next unless bill.present?

      count += 1 unless bill.price == bill.payment_amount
    end
    count
  end

  # Total de deuda de las propiedades de una comunidad en especifico
  def defaulter_properties_total_amount(property_id)
    CalculateUserOutdatedDebt.call(self, property_id)
  end

  # La propiedad más morosa y los meses de morosidad
  def defaultest_property
    months = 0
    property = nil
    morosity_months_by_property = Debt.user_common_debt_count_by_property(self)
    prop_details = properties.select('properties.*, min(debts.priority_date) as min_date').joins(:debts).where('debts.priority_date < ? and debts.money_balance > 0 ', Time.now).group('properties.id')[0]
    if prop_details.present?
      properties.each do |p|
        temp_month = morosity_months_by_property[p.id]&.morosity_months.to_i
        if temp_month.to_i > months
          months = temp_month
          property = p
        end
      end

      return [months, property]
    else
      return [0, nil]
    end
  end

  ###########################
  ######### Ability #########
  ###########################

  def admin?
    admin
  end

  def access_control?
    email == ENV['ACCESS_CONTROL_EMAIL']
  end

  # Use it only with current_user becouse only the user have the eager_load properties
  def is_community_part_owner?
    properties.any?(&:active)
  end

  # Deprecado
  def is_committee(community_id)
    !community_users.where('active = ? and role_code > ? and community_id = ?', true, CommunityUser.reversed_roles('Administrador'), community_id).empty?
  end

  def is_community_admin(community_id)
    community_users.any? do |cu|
      cu.active && cu.community_id == community_id.to_i &&
        cu.role_code == CommunityUser.reversed_roles('Administrador')
    end
  end

  def is_super_or_community_admin(community_id)
    admin? || is_community_admin(community_id)
  end

  def super_or_admin_community(community_id)
    if is_super_or_community_admin(community_id.to_i)
      Community.where(active: true).find(community_id.to_i)
    else
      Community.active.find(community_id.to_i)
    end
  end

  def is_community_manager(community_id)
    community_users.any? do |cu|
      cu.active && cu.community_id == community_id &&
        cu.role_code == CommunityUser.reversed_roles('Encargado')
    end
  end

  def is_community_admin_to_manager(community_id, manager_id)
    !CommunityUser.where(active: true, community_id: community_id, user_id: manager_id, role_code: CommunityUser.reversed_roles('Encargado')).empty?
  end

  def is_community_administrator?
    admin_communities.present?
  end

  def is_in_charge_of_some_community?
    community_users.any? { |u| u.role_code == 4 } # encargado de alguna comunidad
  end

  # Es válido para todo administrador, encargado y súper admin
  def can_manage_community(community_id)
    admin? || manageable_communities.ids.include?(community_id)
  end

  def active_resident_in_community(community_id)
    property_users.joins(property: :community).where(active: true, community: { id: community_id }).present?
  end

  # Profile select
  def with_multiple_profiles?
    return false if demo || admin?

    profiles_count = 0
    profiles_count += 1 if is_community_part_owner?
    profiles_count += 1 if is_community_manager?
    profiles_count += 1 if is_community_committee?
    return true if profiles_count > 1

    profiles_count += 1 if is_community_admin?
    return true if profiles_count > 1

    return false if profiles_count.zero?

    profiles_count += 1 if is_real_estate_agency?
    profiles_count > 1
  end

  def community_profile(community_id:, cached: false)
    return nil unless community_id

    if cached
      profiles.detect { |profile| profile.community_id == community_id }
    else
      profiles.find_by(community_id: community_id)
    end
  end

  def can_manage_communities?
    return false if demo

    can_use_dashboard? || admin?
  end

  def can_use_dashboard?
    is_community_admin? || is_community_manager? || is_real_estate_agency? || is_community_committee?
  end

  def community_resident?(community_id:)
    properties.where(community_id: community_id).present?
  end

  ##################################
  ######### Authentication #########
  ##################################

  def self.authenticate(email, password)
    return false unless email.present?

    # TODO: replace where with find_by after the rake task deleting users with the same email is done in production
    users = where(email: email.downcase)

    # If it founds one active user with the email and one or more inactive, sorts the array placing the active user first
    users = users.sort_by { |u| u.active ? 0 : 1 } if users.size > 1
    user = users.first

    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt) && (((user.try_login < 10) && !user.admin?) || (user.admin? && (user.try_login < 3)))
      user.sign_in_count = user.sign_in_count + 1
      user.try_login = 0
      user.last_sign_in_at = Time.now
      user.save
      user
    else
      if user
        user.update_attribute(:try_login, user.try_login + 1)
        return false if (user.try_login >= 3) && user.admin?
        return false if user.try_login >= 10
      end
      nil
    end
  end

  def valid_password?(password)
    password_hash == BCrypt::Engine.hash_secret(password, password_salt)
  end

  def encrypt_password
    return unless password.present?

    self.password_salt = BCrypt::Engine.generate_salt
    self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
  end

  def reset_password(new_password, confirm_password, token)
    raise ArgumentError, I18n.t('messages.errors.users.confirm_and_new') unless new_password == confirm_password
    raise ArgumentError, I18n.t('messages.errors.users.short_password') unless new_password&.length > 3

    self.password = new_password
    if save
      reset_login_attempts
      Token.delete token
      true
    else
      false
    end
  end

  def reset_login_attempts
    update(first_login: false, last_sign_in_at: Time.now, try_login: 0)
  end

  def track_mobile_sign_in
    self.mobile_sign_in_count += 1
    self.last_mobile_sign_in_at = Time.now
    save
  end

  # G+ login
  def self.from_oauth(auth)
    return false unless auth

    user = User.find_by_email(auth['info']['email'])
    oauth_user = user&.user_oauths&.find_by_provider(auth['provider'])
    oauth_user&.user || create_with_oauth(auth)
  end

  def self.create_with_oauth(auth)
    oauth_user = User.find_by_email(auth['info']['email'].downcase) if auth['info']['email'].present?
    oauth_user = UserOauth.find_by(uid: auth['info']['uid'])&.user if auth['provider'] == @apple && oauth_user.nil?
    return User.find_by_email('demo_app@comunidadfeliz.cl') if auth['provider'] == @apple && auth['info']['email'].nil? && oauth_user.nil? && ENV['APPLE_TESTER_DEMO_USER'] == 'true'
    return nil if auth['provider'] == @apple && auth['info']['email'].nil? && oauth_user.nil? && ENV['APPLE_TESTER_DEMO_USER'] == 'false'

    unless oauth_user
      create! do |user|
        user.email = auth['info']['email']
        user.password = SecureRandom.hex
        user.first_name = auth['info']['first_name']
        user.last_name = auth['info']['last_name']
        user.image = auth['info']['image'] if auth['info']['image'].present?
        user.first_login = false
        user.created_by_oauth = true
        oauth_user = user
      end
    end
    user_oauth = oauth_user.user_oauths.find_or_create_by(provider: auth['provider'])
    user_oauth.oauth_token = auth['oauth_token']
    user_oauth.uid = auth['info']['uid'] if auth['info'].has_key?('uid')
    user_oauth.save!
    oauth_user
  end

  def new?
    communities.size.zero? && property_user_requests.size.zero?
  end

  def is_community_member?
    communities.size.zero?
  end

  ## Nueva interface notificaciones##
  ###################################

  ##valores number_notifications
  ## 0-3 modal de acceder en a la nueva interface (se muestra un maximo de 3 veces)
  ## 4   usuario accedio a nueva interface
  ## 5   modal de evaluacion de interface (solo se muestra una vez)

  # evalua si mostrar notificacion para probar nueva interfaz
  def show_new_interface?
    !new_interface && number_notifications < 3 && last_notification_date <= DateTime.now
  end

  def show_rate_new_interface_disabled?
    !new_interface && number_notifications == 4
  end

  def reject_new_interface
    case number_notifications
    when 0
      self.last_notification_date = DateTime.now + 1.day
    when 1
      self.last_notification_date = DateTime.now + 3.day
    end
    self.number_notifications = number_notifications + 1
    self.save
  end

  def activate_new_interface
    self.new_interface = true
    self.number_notifications = 4
    self.save
  end

  ##################################
  ######### Better Queries #########
  ##################################
  def is_community_admin?
    admin || community_users.any? do |cu|
      cu.active && cu.role_code == 1 && cu.community.active
    end
  end

  def is_community_committee?
    admin || community_users.any? do |cu|
      cu.active && cu.role_code == CommunityUser.reversed_roles('Directiva') &&
        cu.community.active
    end
  end

  def is_community_manager?
    admin || community_users.any? do |cu|
      cu.active && cu.role_code == CommunityUser.reversed_roles('Encargado') &&
        cu.community.active
    end
  end

  def is_real_estate_agency?
    real_estate_agency_id.present?
  end

  def is_part_owner?
    properties.present?
  end

  def self.search(values)
    PropertyUsers::SearchByName::UsersStrategy.new(search_params: values).build_query
  end

  def self.joins_by_first_property(community_id:, role:, property_name:, active: true)
    role = if role.blank?
             Constants::PropertyUser::ROLES.keys.map {|r| "'#{r}'" }.join(',')
           else
             "'#{role}'"
           end
    joins(%(
      INNER JOIN (
        SELECT DISTINCT ON(property_users.user_id) property_users.user_id,
          properties.name
        FROM property_users
        INNER JOIN properties
          ON properties.id = property_users.property_id
        WHERE properties.community_id = #{community_id}
          AND (property_users.role in (#{role}))
          AND (#{property_name.blank? || Property.search(property_name.to_s, true)})
          AND property_users.active = #{active}
        ORDER BY
          property_users.user_id,
          CASE WHEN LEFT("properties"."name", 1) ~ '^\\d+'
            THEN ''
            ELSE substring("properties"."name", '\\D+')
          END,
          substring("properties"."name", '\\d+')::numeric,
          "properties"."name"
      ) AS properties
      ON properties.user_id = users.id
    ))
  end

  def generate_password
    key = SecureRandom.hex
    key = key.delete('./')
    self.password = key[5..9]
  end

  def self.find_by_full_name(first_name, last_name, mother_last_name)
    full_name = [first_name, last_name, mother_last_name].compact
    full_name = full_name.join.downcase.delete(" \t")
    find_by(%(unaccent(lower(replace(
      COALESCE(users.first_name, '') ||
      COALESCE(users.last_name, '') ||
      COALESCE(users.mother_last_name, ''), ' ', '')))
      = unaccent(lower(trim(?)))), full_name)
  end

  #############
  ### EXCEL ###
  #############

  def self.excel_import(params, community, property = nil, excel_upload = nil, records = [])
    user = community.users.find(params[:user][:id].to_i) if params[:user][:id].present?
    unless user.present?
      user = records.select { |d| d.email == params[:user][:email].to_s.delete("\t ").downcase && d.email.to_s.strip.present? }[0]
    end
    puts user.email if user.present?
    if params[:user][:email].present? && !user.present?
      user = User.find_by_email(params[:user][:email].to_s.delete("\t ").downcase)
    end
    unless params[:force_email].present? && params[:force_email].to_s == true.to_s
      # Sólo busca por nombre completo cuando tiene al menos el first_name y no tiene email entre los parámetros.
      if params[:user][:first_name].present? && params[:user][:email].blank? && !user.present?
        user = community.users.find_by_full_name(params[:user][:first_name], params[:user][:last_name], params[:user][:mother_last_name])
      end
    end

    if user.present?
      user.active = true
      user.assign_attributes(excel_params(params))
    else
      par = excel_params(params)
      par[:email] = par[:email].to_s.delete(" \t").downcase
      par[:email] = par[:email].split(',')[0] if par[:email].include?(',')
      par[:email] = I18n.transliterate(par[:email]) if excel_upload&.unsafe_import?
      user = User.new(par)
      user.generate_password # if ( !excel_params(params)[:password].present? or excel_params(params)[:password].to_s != "")
      user.active = true
      if excel_upload.present?
        user.importer_id = excel_upload.id
        user.importer_type = excel_upload.class.name
      end
    end
    user.current_attributes(community_id: community.id, user_id: excel_upload&.uploaded_by)
    user.save

    if property && user.valid?
      property_user = user.property_users.where(property_id: property.id).order('created_at desc').first_or_initialize
      if excel_upload.present?
        property_user.importer_id = excel_upload.id
        property_user.importer_type = excel_upload.class.name
      end
      property_user.assign_attributes(PropertyUser.excel_params(params)) if params[:property_user].present?
      property_user.in_charge = true if params[:property_user][:owner]&.downcase.eql?('si')
      property_user.save if property_user.valid?
    end
    records << user
    puts "records: #{records.length}"
    [user, property_user]
  end

  def email?
    email.present?
  end

  def self.massive_excel_import(params)
    return I18n.t(:user_not_found, scope: %i[errors excel_upload]) unless params[:user].present?

    community = Community.find_by(id: params[:community_id])
    return I18n.t(:community_not_found, scope: %i[errors excel_upload]) unless community.present?

    email_param = params[:user][:email].to_s.delete(" \t").downcase
    user = community.users.find_by(email: email_param) if email_param.present?
    if params[:user][:first_name].present? || params[:user][:last_name].present?
      user ||= community.users.find_by_full_name(params[:user][:first_name], params[:user][:last_name], params[:user][:mother_last_name])
    end
    return I18n.t(:user_not_found, scope: %i[errors excel_upload]) unless user.present?

    property_param = params[:property][:address].to_s.delete("\t").strip
    property_id = user.properties.find_by(community_id: community.id, name: property_param)&.id
    return I18n.t(:property_not_found, scope: %i[errors excel_upload]) unless property_id.present?

    user.email = I18n.transliterate(email_param) unless user.email.present?
    user.current_attributes(community_id: community.id)
    user.update(massive_import_params(params).reject { |_k, v| v.to_s.strip.blank? })
    key = user.tokens.first_or_create
    NotifyRecoverPasswordJob.perform_later(
      _community_id: community.id, community_id: community.id, user_id: user.id,
      token: key.value, new_user: false,
      subject: I18n.t(:subject, scope: %i[mailers notify_recover_password]),
      _message: I18n.t(:notify_recover_password, scope: %i[jobs])
    )
    errors = user.errors.full_messages
    if params[:property_user]&.fetch(:owner, nil).present?
      owner_param = if params[:property_user][:owner].delete(" \t").casecmp('copropietario').zero?
                      :owner
                    else
                      :lessee
                    end
      property_user = user.property_users.find_by(property_id: property_id)
      unless property_user&.update(role: owner_param)
        errors << I18n.t(:property_user_not_found, scope: %i[errors excel_upload])
      end
    end
    errors.join(', ')
  end

  def self.import_blank_user(property, excel_upload)
    user = User.new
    user.generate_password
    user.active = true
    user.importer_id = excel_upload.id
    user.importer_type = excel_upload.class.name
    user.current_attributes(
      community_id: excel_upload.community_id, user_id: excel_upload.uploaded_by
    )
    user.save

    property_user = user.property_users.where(property_id: property.id).order('created_at desc').first_or_initialize
    property_user.importer_id = excel_upload.id
    property_user.importer_type = excel_upload.class.name
    property_user.save if property_user.present?

    [user, property_user]
  end

  def self.indep_excel_import(params, community, property, excel_upload = nil, check_validated = false)
    params = Identifications::UserParamsHandler.call(params, community)
    user = User.find_by_email params[:user][:email].to_s.strip if params[:user][:email].present?
    # Sólo busca por nombre completo cuando tiene al menos el first_name y no tiene email entre los parámetros.
    if params[:user][:first_name].present? && params[:user][:email].blank? && !user.present?
      user = community.users.find_by_full_name(params[:user][:first_name], params[:user][:last_name], params[:user][:mother_last_name])
    end

    # check
    unless user.present?
      user = User.new(excel_params(params))
      user.generate_password # if (!excel_params(params)[:password].present? or excel_params(params)[:password].to_s != "")
      if excel_upload.present?
        user.importer_id = excel_upload.id
        user.importer_type = excel_upload.class.name
      end
    end
    user.active = true
    user.current_attributes(
      community_id: community.id, user_id: excel_upload&.uploaded_by
    )

    if user.save
      property_user = user.property_users.where(property_id: property.id).order('created_at desc').first_or_create(excel_upload_id: (excel_upload.present? ? excel_upload.id : nil))
      if excel_upload.present?
        property_user.importer_id = excel_upload.id
        property_user.importer_type = excel_upload.class.name
      end
      property_user.save if property_user.present?
    end

    [user, property_user]
  end

  # HARD DELETE!
  def self.undo_excel_import(importer)
    users_to_destroy = importer.users
      includes(:admin_community_users, :admin_communities, :committee_community_users, :committee_communities,
      :attendant_community_users, :attendant_communities, :identifications, :user_oauths)
    users_to_destroy.each do |user|
      unless (user.communities.count > 1) || user.admin_communities.present? || user.committee_communities.present? || user.attendant_communities.present?
        user.destroy
      end
    end

    prop_users_to_destroy = importer.property_users
    prop_users_to_destroy.each(&:destroy)
  end

  def self.excel_params(params)
    params.require(:user).permit(:first_name, :last_name, :mother_last_name, :email, :phone, :rut, :rfc, :country_code, identifications_attributes: %i[identity identity_type])
  end

  def self.update_excel_params(params)
    params.require(:user).permit(:first_name, :last_name, :mother_last_name, :email, :phone, :rut, :rfc, :country_code, identifications_attributes: %i[id identity identity_type])
  end

  def self.massive_import_params(params)
    params.require(:user).permit(:phone, :rut)
  end

  def self.unknown(attributes = nil)
    user = where(unknown_user: true).first_or_create(password: 'comunidadfeliz')
    user.attributes = attributes if attributes
    user
  end

  def set_default_password(new_password)
    new_pswd = new_password.to_s.gsub('{email_3}', email.first(3))
    success = update(password: new_pswd)
    [new_pswd, success]
  end

  def get_properties_options(current_community)
    if is_community_admin?
      current_community.properties.merge(Property.order_by_name)
    else
      properties.merge(Property.order_by_name).includes(:community)
    end
  end

  def get_focus_group_and_country_codes(community_id, logged_as_administrator, logged_as_property_user)
    focus_group = []
    country_codes = []
    # si es administrador
    if is_community_administrator? && logged_as_administrator
      community = Community.find_by_id(community_id)
      country_codes << community&.country_code
      focus_group << Advertisement.groups[:administrators]
      # verifica que tenga el modulo webpay activo
      focus_group << Advertisement.groups[:with_webpay] if community&.get_setting_value('online_payment') == 1
    elsif is_part_owner? && logged_as_property_user # si es copropietario
      country_codes = communities.distinct.pluck(:country_code)
      focus_group << Advertisement.groups[:property_users]
      # verifica que tenga el modulo webpay activo en al menos una de las comunidades
      focus_group << Advertisement.groups[:with_webpay] if communities.joins(:settings).where(settings: { code: 'online_payment', value: 1 }).any?
    elsif is_real_estate_agency? && logged_as_administrator
      country_codes = real_estate_agency_communities.pluck(:country_code)
      focus_group << Advertisement.groups[:real_estate_agency]
      focus_group << Advertisement.groups[:with_webpay] if real_estate_agency_communities.joins(:settings).where(settings: { code: 'online_payment', value: 1 }).any?
    elsif is_in_charge_of_some_community?
      country_codes = Community.where(id: community_users.pluck(:community_id)).distinct.pluck(:country_code)
      focus_group << Advertisement.groups[:in_charge]
    end
    focus_group << Advertisement.groups[:without_webpay] unless focus_group.include?(Advertisement.groups[:with_webpay])
    [focus_group, country_codes]
  end

  # Retorna el conjunto de publicidades de acuerdo al usuario en sesion
  def get_advertisements(community_id, logged_as_administrator, logged_as_property_user)
    focus_group, country_codes = get_focus_group_and_country_codes(community_id, logged_as_administrator, logged_as_property_user)
    extra_conditions = <<~SQL
      (
        (
          advertisements.days_without_show > 0
            AND NOW()::date >= (advertisement_users.last_viewed::date + (interval '1 day' * advertisements.days_without_show))
        )
        OR advertisement_users.last_viewed IS NULL
      )
      AND advertisements.country_codes && ARRAY[?]::varchar[]
      AND advertisements.focus_group && ARRAY[?]::varchar[]
    SQL
    Advertisement.for_user(id).where(active: true).where(
      extra_conditions, country_codes, focus_group
    ).distinct
  end

  # Retorna nil si no encuentra resultados
  def get_random_advertisement(community_id, logged_as_administrator, logged_as_property_user)
    get_advertisements(community_id, logged_as_administrator, logged_as_property_user).sample
  end

  def get_type_user
    user_types = []
    user_types << 'Administrador' if is_community_administrator?
    user_types << 'Copropietario' if is_part_owner?
    user_types << 'Inmobiliaria' if is_real_estate_agency?
    user_types.empty? ? 'No definido' : user_types.join(', ')
  end

  # Búsqueda por focus group, recibe un array de argumentos
  def self.by_focus_group(*args)
    # Castea los caracteres incluyendo los booleanos
    args.collect! { |item| ActiveRecord::Type::Integer.new.cast(item) }

    args.reject!(&:blank?)

    group = args.collect { |i| i + 1 }
    (1..5).collect { |i| group.insert((i - 1), 0) unless group.include?(i) }
    if !group.include?(1) && !group.include?(2) && !group.include?(3)
      group[0] = 1
      group[1] = 2
      group[2] = 3
    end
    if !group.include?(4) && !group.include?(5)
      group[3] = 4
      group[4] = 5
    end

    includes(:advertisement_users, :property_users, :admin_community_users, property_users: [property: [community: :settings]], admin_community_users: [community: :settings], real_estate_agency: [communities: :settings]).where(%( advertisement_users.clicked_count > 0 AND ((community_users.id IS NOT NULL AND 1 IN (?)) OR (property_users.id IS NOT NULL AND 2 IN (?)) OR (users.real_estate_agency_id IS NOT NULL AND 3 IN (?))) AND ((settings.code = 'online_payment' AND settings.value = 1) AND 4 IN (?) OR (((settings.code = 'online_payment' OR settings.code IS NULL) AND (settings.value = 0 OR settings.value IS NULL)) AND 5 IN (?)))  ), group, group, group, group, group).references(:advertisement_users, property_users: [property: [community: :settings]], admin_community_users: [community: :settings], real_estate_agency: [communities: :settings])
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[by_focus_group]
  end

  def allowed_common_spaces(community_id, property_id)
    ActiveRecord::Base.connection.execute(
      <<~SQL
        select
        distinct ce.id,
        ce.created_at
        from common_spaces ce
        join (
          select
            c.id community_id,
            p.id property_id,
            coalesce(sum(d.money_balance), 0) property_debt
          from properties p
          join communities c on c.id = p.community_id
            and c.active = true
            and c.accessible = true
          join property_users pu on p.id = pu.property_id
          left join debts d on d.property_id = p.id and d.paid = false and d.priority_date <= '#{Time.now}'
          where pu.user_id = #{id}
            and p.community_id = #{community_id}
            and p.active = true
            and pu.active = true
            #{"and p.id = #{property_id}" if property_id.present?}
          group by p.id, c.id
        ) user_community_debts  on user_community_debts.community_id = ce.community_id
        where ce.active = true
          and ce.available = true
          and (
            ce.maximum_debt_allowed_active = false
            or coalesce(ce.maximum_debt_allowed, 0) >= user_community_debts.property_debt
          )
        order by ce.created_at asc
      SQL
    )
  end

  def duplicated_email?(new_email)
    new_email.present? &&
      new_email.delete("\t").strip != '' &&
      User.where('email = ? AND (id != ? OR ? IS NULL)', new_email.to_s.delete("\t").strip.downcase, id, id).first.present?
  end

  def email_change
    return false if email.blank?

    if @old_email.present? && email.to_s.delete("\t").strip.downcase != @old_email.to_s.delete("\t").strip.downcase
      self.validate_email = email
      self.email = @old_email
    end
    @old_email = nil
    true
  end

  def email_activate(token, community)
    dest_user = found_destination_user
    if dest_user
      update(validate_email: nil)
      UserManager::TransferProperties.call(origin_user: self, community: community, destination_user: dest_user)
    else
      update(email: validate_email, validate_email: nil)
    end
    token.destroy unless errors.messages.present?
    dest_user ||= self
    dest_user
  end

  def deactivate_account
    DeactivateUserJob.perform_later(
      user_id: id,
      user_email: email,
      _message: I18n.t('jobs.deactivate_user')
    )
    Rails.logger.debug "Removing user email #{email} ..."
    update(email: nil)
  end

  def found_destination_user
    return false unless duplicated_email?(validate_email)

    User.where('email = ? AND (id != ? OR ? IS NULL)', validate_email.to_s.delete("\t").strip.downcase, id, id).first
  end

  def assigned_subdomain(community)
    return nil if community.nil?

    cusers = community_users.where('community_id = ? and role_code > 0 and active = true', community.id)
    if cusers.size.positive?
      cusers.first.server&.subdomain
    else
      server&.subdomain
    end
  end

  def delete_info
    property_users&.update_all(active: false)
    particular_address&.update(direction: nil, postal_code: nil, latitude: nil, longitude: nil, country: nil, administrative_area_level_1: nil, locality: nil, country_code: nil)
    fiscal_identification&.update(postal_code: nil, cfdi_use: nil, fiscal_regime: nil)
    identifications&.find_by(identity: rut)&.destroy
    self.update(active: false, first_name: nil, last_name: nil, mother_last_name: nil, email: nil, phone: nil, rut: nil)
  end

  def resident_status
    properties_in_charge = property_users.in_charge

    return :in_charge_with_debts if properties_in_charge.with_debts.count.positive?

    return :in_charge_without_debts if properties_in_charge.count.positive?

    :not_in_charge
  end

  def set_slug
    return if slug.present?

    slug = %i[first_name last_name].map { |met| send(met) }
      .join.gsub(' ', '-').gsub('.', '')
      .underscore.dasherize + '-' + SecureRandom.uuid

    self.assign_attributes(slug: slug)
  end

  def facebook_oauth?
    user_oauths.where(provider: %w[facebook FACEBOOK]).exists?
  end

  def password_complexity
    return if !!password.match(Constants::Users::SUPERADMIN_PASSWORD_PATTERN)

    errors.add(:password, I18n.t('activerecord.errors.models.user.attributes.password.password_complexity'))
  end

  def self.generate_secure_password
    randon_string = User.generate_unique_secure_token
    randon_string[rand(randon_string.size)] = Constants::Users::SPECIAL_PASSWORD_CHARS.sample
    randon_string =~ Constants::Users::SUPERADMIN_PASSWORD_PATTERN ? randon_string : generate_secure_password
  end

  def address_direction
    particular_address.direction
  end

  def basic_info
    {
      first_name: first_name,
      last_name: last_name,
      phone: phone,
      user_id: id
    }
  end

  def mfa_expired?
    (Date.current - mfa_last_updated_at).to_i >= Constants::Users::MFA_EXPIRATION
  end
end
