# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_11_13_152356) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "account_contact_types", ["administrators", "main_contact", "other"]
  create_enum "request_status", ["pending", "rejected", "cancelled", "accepted"]

  create_table "account_contacts", force: :cascade do |t|
    t.bigint "account_id"
    t.enum "contact_type", default: "main_contact", null: false, enum_type: "account_contact_types"
    t.string "email"
    t.index ["account_id"], name: "index_account_contacts_on_account_id"
  end

  create_table "account_summary_sheet_bills", id: :serial, force: :cascade do |t|
    t.integer "account_summary_sheet_id"
    t.integer "bill_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_summary_sheet_id"], name: "index_account_summary_sheet_bills_on_account_summary_sheet_id"
    t.index ["bill_id"], name: "index_account_summary_sheet_bills_on_bill_id"
  end

  create_table "account_summary_sheets", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "period_expense_id"
    t.float "price"
    t.float "later_balance"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "summary_sheet_updated_at", precision: nil
    t.string "group_name", default: "Grupo"
    t.string "bill_number"
    t.boolean "payments_generated", default: true
    t.datetime "html_summary_sheet_updated_at", precision: nil
    t.string "alphanumeric_code"
    t.string "slug"
    t.string "summary_sheet"
    t.string "html_summary_sheet"
    t.index ["bill_number"], name: "index_account_summary_sheets_on_bill_number", unique: true
    t.index ["slug"], name: "index_account_summary_sheets_on_slug", unique: true
  end

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.string "name", default: "Principal"
    t.integer "previous_balance", default: 0
    t.string "rut", default: ""
    t.string "business_name", default: ""
    t.string "address", default: ""
    t.string "commune", default: ""
    t.string "city", default: ""
    t.string "activity", default: ""
    t.string "contact_email", default: ""
    t.string "petitioner_rut", default: ""
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "good_faith", default: true
    t.boolean "bill_irs_with_invoice", default: false
    t.string "country_code", default: "CL"
  end

  create_table "additional_concepts", force: :cascade do |t|
    t.bigint "debt_id"
    t.integer "concept_type"
    t.string "name"
    t.integer "amount_type"
    t.decimal "amount", precision: 22, scale: 2
    t.integer "days_delta"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["debt_id"], name: "index_additional_concepts_on_debt_id"
  end

  create_table "addresses", force: :cascade do |t|
    t.string "direction"
    t.string "postal_code"
    t.float "latitude"
    t.float "longitude"
    t.string "country"
    t.string "administrative_area_level_1"
    t.string "locality"
    t.boolean "is_created_by_google_maps"
    t.string "addressable_type"
    t.integer "addressable_id"
    t.string "country_code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "advances", id: :serial, force: :cascade do |t|
    t.integer "period_expense_id"
    t.integer "price"
    t.integer "employee_id"
    t.string "comment"
    t.datetime "voucher_updated_at", precision: nil
    t.datetime "documentation_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "paid_at", precision: nil
    t.integer "service_billing_id"
    t.boolean "active", default: true
    t.datetime "deactivated_at", precision: nil
    t.boolean "recurrent", default: false
    t.string "documentation"
    t.string "voucher"
    t.string "creator_type"
    t.bigint "creator_id"
    t.string "updater_type"
    t.bigint "updater_id"
    t.index ["creator_type", "creator_id"], name: "index_advances_on_creator"
    t.index ["period_expense_id"], name: "index_advances_on_period_expense_id"
    t.index ["service_billing_id"], name: "index_advances_on_service_billing_id"
    t.index ["updater_type", "updater_id"], name: "index_advances_on_updater"
  end

  create_table "advertisement_users", force: :cascade do |t|
    t.bigint "advertisement_id"
    t.bigint "user_id"
    t.integer "viewed_count", default: 0
    t.integer "clicked_count", default: 0
    t.boolean "active", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.date "last_viewed"
    t.index ["advertisement_id"], name: "index_advertisement_users_on_advertisement_id"
    t.index ["user_id"], name: "index_advertisement_users_on_user_id"
  end

  create_table "advertisements", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "photo_updated_at", precision: nil
    t.string "url"
    t.string "focus_group", default: [], array: true
    t.integer "viewed_count", default: 0
    t.integer "clicked_count", default: 0
    t.string "button_text", null: false
    t.boolean "active", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "optionally_show", default: true
    t.integer "days_without_show", default: 1
    t.string "country_codes", default: [], array: true
    t.string "photo"
  end

  create_table "aliquots", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "proration_type", default: 1
    t.integer "community_id", null: false
    t.float "total_area", default: 0.0
    t.string "bill_header_1", default: "Prorrateo "
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_aliquots_on_community_id"
  end

  create_table "aliquots_posts", id: false, force: :cascade do |t|
    t.bigint "aliquot_id", null: false
    t.bigint "post_id", null: false
    t.index ["aliquot_id"], name: "index_aliquots_posts_on_aliquot_id"
    t.index ["post_id"], name: "index_aliquots_posts_on_post_id"
  end

  create_table "answers", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.integer "option_id"
    t.integer "user_id"
    t.string "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.float "weight", default: 1.0
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["user_id"], name: "index_answers_on_user_id"
  end

  create_table "api_keys", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "public_key"
    t.string "access_token"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "user_id"
    t.string "token", null: false
    t.string "version", default: "0.0.0", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "assets", id: :serial, force: :cascade do |t|
    t.datetime "document_updated_at", precision: nil
    t.string "documentable_type"
    t.integer "documentable_id"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "confirmed", default: true
    t.integer "community_id"
    t.string "document"
    t.index ["documentable_type", "documentable_id"], name: "index_assets_on_documentable_type_and_documentable_id"
  end

  create_table "assign_payments", id: :serial, force: :cascade do |t|
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.integer "payment_id"
    t.integer "debt_id"
    t.datetime "assigned_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.date "paid_at"
    t.integer "interest_id"
    t.datetime "should_bill_interest", precision: nil
    t.index "EXTRACT(year FROM paid_at)", name: "index_assign_payments_on_EXTRACT_year_FROM_paid_at"
    t.index ["debt_id"], name: "index_assign_payments_on_debt_id"
    t.index ["payment_id"], name: "index_assign_payments_on_payment_id"
  end

  create_table "balances", id: :serial, force: :cascade do |t|
    t.string "name"
    t.decimal "money_balance", precision: 19, scale: 4, default: "0.0"
    t.string "ref_class"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.boolean "selected"
    t.bigint "community_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.index ["community_id"], name: "index_bank_accounts_on_community_id"
  end

  create_table "banking_settings", force: :cascade do |t|
    t.bigint "community_id"
    t.string "bank"
    t.string "account_type"
    t.string "account_number"
    t.string "beneficiary_name"
    t.string "clabe"
    t.string "email"
    t.string "beneficiary_identification"
    t.boolean "validated", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "costs_center"
    t.string "stp_account_number"
    t.string "costs_center_name"
    t.string "costs_center_clabe"
    t.string "payer_tin"
    t.string "payer_name"
    t.string "beneficiary_tin"
    t.index ["community_id"], name: "index_banking_settings_on_community_id"
  end

  create_table "banred_infos", force: :cascade do |t|
    t.bigint "community_id"
    t.string "entity_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_banred_infos_on_community_id"
  end

  create_table "base_packages", force: :cascade do |t|
    t.string "name"
    t.float "base_price"
    t.string "country_code"
    t.integer "package_type"
    t.string "currency_type"
    t.integer "months_to_bill"
    t.integer "invoice_type"
    t.float "exempt_percentage", default: 0.0, null: false
    t.boolean "active"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "price_type", default: 0, null: false
    t.float "minimum_price", default: 0.0, null: false
  end

  create_table "bill_details", id: :serial, force: :cascade do |t|
    t.integer "bill_id"
    t.string "title"
    t.string "description", default: ""
    t.string "description2", default: ""
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.string "ref_object_class"
    t.integer "ref_object_id"
    t.float "referential_price", default: 0.0
    t.float "referential_price2", default: 0.0
    t.boolean "is_past_common_expense", default: false
    t.boolean "is_discount", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "description3"
    t.string "description4"
    t.string "aliquot_name"
    t.integer "aliquot_id", default: 0
    t.integer "ref_object_id2"
    t.integer "excel_upload_id"
    t.string "importer_type"
    t.integer "importer_id"
    t.index ["bill_id"], name: "index_bill_details_on_bill_id"
    t.index ["bill_id"], name: "index_on_bill_details_community_bid", where: "((ref_object_class)::text = 'Community'::text)"
    t.index ["importer_type", "importer_id"], name: "index_bill_details_on_importer_type_and_importer_id"
  end

  create_table "bills", id: :serial, force: :cascade do |t|
    t.integer "state", default: 1
    t.integer "period_expense_id"
    t.integer "property_id"
    t.bigint "active_common_expense_id"
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.decimal "base_price", precision: 19, scale: 4, default: "0.0"
    t.decimal "later_balance", precision: 19, scale: 4, default: "0.0"
    t.datetime "bill_updated_at", precision: nil
    t.date "expiration_date"
    t.datetime "notified_at", precision: nil
    t.date "paid_at"
    t.datetime "receipt_updated_at", precision: nil
    t.string "bar_code"
    t.boolean "dummy", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "fixed_common_expense", precision: 19, scale: 4, default: "0.0"
    t.boolean "initial_setup", default: false
    t.integer "folio"
    t.boolean "split", default: false
    t.string "split_name"
    t.decimal "split_price", precision: 19, scale: 4
    t.string "split_owner_name"
    t.string "split_description", default: "Descuento Boleta Compartida"
    t.datetime "short_bill_updated_at", precision: nil
    t.datetime "split_bill_updated_at", precision: nil
    t.string "bill_number"
    t.integer "excel_upload_id"
    t.boolean "main", default: true
    t.datetime "html_bill_updated_at", precision: nil
    t.datetime "html_short_bill_updated_at", precision: nil
    t.datetime "html_split_bill_updated_at", precision: nil
    t.string "bill"
    t.string "receipt"
    t.string "short_bill"
    t.string "split_bill"
    t.string "html_bill"
    t.string "html_short_bill"
    t.string "html_split_bill"
    t.string "importer_type"
    t.integer "importer_id"
    t.integer "scan_count", default: 0, null: false
    t.index ["active_common_expense_id"], name: "index_bills_on_active_common_expense_id"
    t.index ["bill_number"], name: "index_bills_on_bill_number"
    t.index ["importer_type", "importer_id"], name: "index_bills_on_importer_type_and_importer_id"
    t.index ["period_expense_id"], name: "index_bills_on_period_expense_id"
    t.index ["property_id"], name: "index_bills_on_property_id"
  end

  create_table "black_list_guests", id: :serial, force: :cascade do |t|
    t.integer "property_id", null: false
    t.string "rut", null: false
    t.string "name"
    t.boolean "active", default: true
    t.string "comment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "blacklists", id: :serial, force: :cascade do |t|
    t.string "email_to"
    t.string "email_from"
    t.boolean "global"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "blockers", force: :cascade do |t|
    t.datetime "block_date", precision: nil
    t.boolean "block_date_postponed", default: false, null: false
    t.string "blockable_type", null: false
    t.integer "blockable_id", null: false
    t.string "block_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blockable_id", "blockable_type", "block_type"], name: "index_blockers_on_blockable_and_block_type", unique: true
    t.index ["blockable_type", "blockable_id"], name: "index_blockers_on_blockable_type_and_blockable_id"
  end

  create_table "bonus_drafts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "budgets", id: :serial, force: :cascade do |t|
    t.integer "period_expense_id", null: false
    t.string "concept_name", null: false
    t.float "value", default: 0.0, null: false
    t.integer "parent_concept_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["period_expense_id"], name: "index_budgets_on_period_expense_id"
  end

  create_table "bundle_payments", id: :serial, force: :cascade do |t|
    t.integer "price", default: 0
    t.integer "period_expense_id"
    t.datetime "paid_at", precision: nil
    t.integer "folio"
    t.integer "payment_type"
    t.string "payment_number"
    t.string "description"
    t.integer "user_id"
    t.integer "account_summary_sheet_id"
    t.datetime "nullified_at", precision: nil
    t.boolean "nullified", default: false
    t.boolean "issued", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "receipt_notified", default: false
    t.datetime "receipt_notified_at", precision: nil
    t.boolean "undid", default: false
    t.boolean "confirmed", default: false
    t.boolean "generated_pdf", default: false
    t.integer "owner_id"
    t.datetime "voucher_updated_at", precision: nil
    t.integer "excel_upload_id"
    t.string "user_name"
    t.string "user_mail"
    t.integer "nullifier_id"
    t.string "voucher"
  end

  create_table "business_transactions", id: :serial, force: :cascade do |t|
    t.integer "balance_id"
    t.decimal "previous_balance", precision: 19, scale: 4
    t.decimal "transaction_value", precision: 19, scale: 4, default: "0.0"
    t.decimal "later_balance", precision: 19, scale: 4
    t.bigint "origin_id"
    t.string "origin_type"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "reference_id"
    t.string "external_id"
    t.datetime "transaction_date", precision: nil
    t.integer "order", default: 1
    t.boolean "reversed", default: false
    t.index ["balance_id"], name: "index_business_transactions_on_balance_id"
    t.index ["external_id"], name: "index_business_transactions_on_external_id"
    t.index ["origin_id", "origin_type"], name: "index_business_transactions_on_origin_id_and_origin_type"
  end

  create_table "buy_orders", id: :serial, force: :cascade do |t|
    t.integer "webpay_init_transaction_id"
    t.string "payable_type"
    t.integer "payable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "payment_type", default: 0
    t.float "price", default: 0.0
    t.integer "quantity", default: 1
    t.boolean "success", default: false
    t.string "productable_type"
    t.integer "productable_id"
    t.index ["payable_type", "payable_id"], name: "index_buy_orders_on_payable_type_and_payable_id"
    t.index ["productable_type", "productable_id"], name: "index_buy_orders_on_productable_type_and_productable_id"
    t.index ["webpay_init_transaction_id"], name: "index_buy_orders_on_webpay_init_transaction_id"
  end

  create_table "campaign_data", force: :cascade do |t|
    t.integer "campaign_id"
    t.boolean "facebook_share_clicked", default: false
    t.integer "payment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_mobile", default: false
  end

  create_table "campaigns", force: :cascade do |t|
    t.boolean "active"
    t.string "name"
    t.text "banner"
    t.string "description"
    t.string "country_code"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.float "minimal_amount"
    t.string "logo"
    t.text "facebook_share_title"
    t.string "facebook_post_url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "banner_mobile"
    t.string "term_and_conditions_url"
    t.boolean "publish_on_fb_required", default: false
    t.boolean "chances_to_apply_active", default: false
    t.boolean "optional_legend_active", default: false
    t.text "optional_legend"
    t.string "mailing_banner"
    t.integer "category", default: 0
    t.string "redirect_url"
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "sub_name", default: ""
    t.integer "use_counter", default: 0
    t.boolean "public", default: false
    t.integer "community_id"
    t.string "slug"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "hidden_in_bill", default: false
    t.boolean "active", default: true
    t.integer "community_outcomes_setting", default: 0
    t.index ["community_id"], name: "index_categories_on_community_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.datetime "html_document_updated_at", precision: nil
    t.datetime "pdf_document_updated_at", precision: nil
    t.string "certificable_type"
    t.bigint "certificable_id"
    t.string "certificate_type"
    t.string "alphanumeric_code"
    t.datetime "expiration_date", precision: nil
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "pdf_document"
    t.string "html_document"
    t.index ["alphanumeric_code"], name: "index_certificates_on_alphanumeric_code"
    t.index ["certificable_type", "certificable_id"], name: "index_certificates_on_certificable"
  end

  create_table "checkbooks", id: :serial, force: :cascade do |t|
    t.integer "number"
    t.string "serial"
    t.integer "initial"
    t.integer "last"
    t.string "bank"
    t.string "account_number"
    t.integer "community_id"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "checks", id: :serial, force: :cascade do |t|
    t.integer "number"
    t.boolean "nullified", default: false
    t.integer "service_billing_id"
    t.integer "checkbook_id"
    t.float "price", default: 0.0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "period_expense_id"
    t.index ["checkbook_id"], name: "index_checks_on_checkbook_id"
    t.index ["period_expense_id"], name: "index_checks_on_period_expense_id"
    t.index ["service_billing_id"], name: "index_checks_on_service_billing_id"
  end

  create_table "client_user_users", id: :serial, force: :cascade do |t|
    t.integer "client_user_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "client_users", force: :cascade do |t|
    t.integer "main_user_id"
    t.boolean "happy_seal_locked"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "closing_logs", force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.bigint "period_expense_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["period_expense_id"], name: "index_closing_logs_on_period_expense_id"
  end

  create_table "collaborators", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "first_name"
    t.string "last_name"
    t.string "role", null: false
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "community_id", null: false
    t.index ["community_id"], name: "index_collaborators_on_community_id"
  end

  create_table "common_expense_details", force: :cascade do |t|
    t.bigint "common_expense_id"
    t.string "title", default: ""
    t.string "description2", default: ""
    t.string "description", default: ""
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.string "ref_object_class"
    t.integer "ref_object_id"
    t.float "referential_price", default: 0.0
    t.float "referential_price2", default: 0.0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "period_expense_id"
    t.boolean "to_delete", default: false
    t.string "description3"
    t.string "description4"
    t.string "aliquot_name"
    t.integer "aliquot_id", default: 0
    t.integer "ref_object_id2"
    t.index ["common_expense_id"], name: "index_common_expense_details_on_common_expense_id"
  end

  create_table "common_expenses", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.date "expiration_date"
    t.datetime "notified_at", precision: nil
    t.boolean "transaction_confirmed", default: false
    t.boolean "verified", default: false
    t.integer "debt_id"
    t.integer "bill_id"
    t.integer "community_id"
    t.integer "period_expense_id"
    t.integer "property_id"
    t.integer "property_transaction_id"
    t.integer "community_interest_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "fixed_common_expense", precision: 19, scale: 4, default: "0.0"
    t.boolean "initial_setup", default: false
    t.boolean "to_delete", default: false
    t.decimal "non_common_price", precision: 19, scale: 4, default: "0.0"
    t.integer "excel_upload_id"
    t.integer "reference_id"
    t.string "importer_type"
    t.integer "importer_id"
    t.index ["community_id"], name: "index_common_expenses_on_community_id"
    t.index ["importer_type", "importer_id"], name: "index_common_expenses_on_importer_type_and_importer_id"
    t.index ["period_expense_id"], name: "index_common_expenses_on_period_expense_id"
    t.index ["property_id"], name: "index_common_expenses_on_property_id"
    t.index ["property_transaction_id"], name: "index_common_expenses_on_property_transaction_id"
  end

  create_table "common_spaces", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "community_id"
    t.string "scheduling_format"
    t.decimal "price", precision: 19, scale: 4
    t.integer "part_owner_limit", default: 30
    t.integer "common_space_quantity", default: 1
    t.boolean "admin_confirmation", default: true
    t.boolean "active", default: true
    t.boolean "monday", default: true
    t.boolean "tuesday", default: true
    t.boolean "wednesday", default: true
    t.boolean "thursday", default: true
    t.boolean "friday", default: true
    t.boolean "saturday", default: true
    t.boolean "sunday", default: true
    t.time "monday_min_time", default: "2000-01-01 08:00:00"
    t.time "monday_max_time", default: "2000-01-01 23:59:59"
    t.time "tuesday_min_time", default: "2000-01-01 08:00:00"
    t.time "tuesday_max_time", default: "2000-01-01 23:59:59"
    t.time "wednesday_min_time", default: "2000-01-01 08:00:00"
    t.time "wednesday_max_time", default: "2000-01-01 23:59:59"
    t.time "thursday_min_time", default: "2000-01-01 08:00:00"
    t.time "thursday_max_time", default: "2000-01-01 23:59:59"
    t.time "friday_min_time", default: "2000-01-01 08:00:00"
    t.time "friday_max_time", default: "2000-01-01 23:59:59"
    t.time "saturday_min_time", default: "2000-01-01 08:00:00"
    t.time "saturday_max_time", default: "2000-01-01 23:59:59"
    t.time "sunday_min_time", default: "2000-01-01 08:00:00"
    t.time "sunday_max_time", default: "2000-01-01 23:59:59"
    t.string "sunday_min_max", default: "08:00-12:59; 13:00-17:59; 18:00-23:59"
    t.string "monday_min_max", default: "08:00-12:59; 13:00-17:59; 18:00-23:59"
    t.string "tuesday_min_max", default: "08:00-12:59; 13:00-17:59; 18:00-23:59"
    t.string "wednesday_min_max", default: "08:00-12:59; 13:00-17:59; 18:00-23:59"
    t.string "thursday_min_max", default: "08:00-12:59; 13:00-17:59; 18:00-23:59"
    t.string "friday_min_max", default: "08:00-12:59; 13:00-17:59; 18:00-23:59"
    t.string "saturday_min_max", default: "08:00-12:59; 13:00-17:59; 18:00-23:59"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "fund_id"
    t.boolean "available", default: true
    t.integer "time_in_advance", default: 0
    t.integer "time_in_advance_format", default: 0
    t.integer "time_to_cancel", default: 0
    t.integer "time_to_cancel_format", default: 0
    t.boolean "maximum_debt_allowed_active", default: false
    t.float "maximum_debt_allowed", default: 0.0
    t.boolean "charge_on_event_period", default: false
    t.integer "max_time_in_advance", default: 0, null: false
    t.integer "max_time_in_advance_format", default: 0, null: false
    t.index ["community_id"], name: "index_common_spaces_on_community_id"
  end

  create_table "communities", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.text "description"
    t.string "slug"
    t.integer "balance_id"
    t.integer "comuna_id"
    t.float "total_area"
    t.integer "region_id"
    t.integer "expiration_day", default: 22
    t.string "rut"
    t.string "phone"
    t.boolean "sms_enabled", default: true
    t.integer "sms_defaulting_days", default: 2
    t.date "last_sms_sent"
    t.datetime "avatar_updated_at", precision: nil
    t.string "bank"
    t.text "billing_message"
    t.integer "currency_id", default: 1
    t.boolean "demo", default: false
    t.date "available_until"
    t.string "crm_email", default: "comunidadfeliz@pipedrivemail.com"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.float "common_price", default: 0.0
    t.integer "reserve_fund_fixed", default: 0
    t.datetime "signature_updated_at", precision: nil
    t.string "bill_header_1", default: "LIQUIDACIÓN DE GASTOS COMUNES"
    t.string "bill_header_2", default: "AVISO DE COBRO"
    t.datetime "company_image_updated_at", precision: nil
    t.text "last_message"
    t.string "contact_email"
    t.string "contact_phone"
    t.text "mail_text"
    t.text "mail_text_payment"
    t.string "mutual"
    t.float "mutual_value", default: 0.0
    t.integer "account_id"
    t.integer "pricing_package"
    t.boolean "active", default: true
    t.integer "real_estate_agency_id"
    t.string "sucursal_pago_mutual"
    t.float "total_m2", default: 0.0
    t.string "sub_community_name", default: "Torre"
    t.string "prorrateo_name", default: "Prorrateo"
    t.integer "days_pre_due_date", default: 3
    t.integer "days_post_due_date", default: 3
    t.text "email_text_pre_due_date"
    t.text "email_text_post_due_date"
    t.integer "reserve_fund_initial_balance", default: 0
    t.string "city"
    t.integer "amount_to_notify_slow_payers", default: 0
    t.string "ccaf", default: "Sin CCAF"
    t.integer "pricing_id"
    t.integer "installation_step", default: 2
    t.float "morosity_min_amount", default: 0.0
    t.integer "morosity_months", default: 3
    t.text "morosity_text", default: ""
    t.string "community_sendgrid_key"
    t.string "bcc_email"
    t.integer "interest_fund_id"
    t.integer "bill_decimals", default: 5
    t.string "bill_header_3", default: "DETALLE DE EGRESOS GASTO COMÚN DE LA COMUNIDAD"
    t.string "bill_header_4"
    t.string "bill_header_5", default: "Egresos Comunidad"
    t.text "administrator_description"
    t.string "bill_header_6", default: "Prorrateo"
    t.string "bill_header_7", default: "Total a recolectar este mes"
    t.datetime "next_bill_date", precision: nil
    t.boolean "active_billing", default: false
    t.float "isl_value", default: 0.93
    t.boolean "count_csm", default: true
    t.text "comments"
    t.boolean "auto_billing", default: true
    t.string "country_code", default: "CL"
    t.string "contact_name"
    t.datetime "remuneration_signature_updated_at", precision: nil
    t.string "currency_code"
    t.integer "certificate_number"
    t.string "timezone"
    t.boolean "accessible", default: true
    t.integer "defaulting_days", default: 30, null: false
    t.integer "day_of_month_to_notify_defaulty", default: 15
    t.string "charge_notification_message"
    t.datetime "free_period_expiration_date", precision: nil
    t.string "workers_union_rut"
    t.boolean "setting_properties", default: false
    t.text "morosity_title"
    t.integer "op_mail_receiver_id", default: -1
    t.integer "issues_mail_receiver_id", default: -1
    t.integer "common_space_correspondent_id", default: -1
    t.string "avatar"
    t.string "company_image"
    t.string "signature"
    t.string "remuneration_signature"
    t.integer "day_of_month_to_notify_unrecognized_payments", default: 25
    t.datetime "last_insurance_quotation_request_at"
    t.date "expert_administrator_certificate_generated_at"
    t.boolean "lost", default: false
    t.datetime "lost_at"
    t.index ["comuna_id"], name: "index_communities_on_comuna_id"
    t.index ["currency_code"], name: "index_communities_on_currency_code"
    t.index ["region_id"], name: "index_communities_on_region_id"
    t.index ["slug"], name: "index_communities_on_slug", unique: true
  end

  create_table "community_accounts", force: :cascade do |t|
    t.bigint "community_id"
    t.bigint "account_id"
    t.boolean "primary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_community_accounts_on_account_id"
    t.index ["community_id"], name: "index_community_accounts_on_community_id"
  end

  create_table "community_descriptions", id: :serial, force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.integer "community_id"
    t.integer "param_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "community_interests", id: :serial, force: :cascade do |t|
    t.integer "community_id"
    t.boolean "fixed", default: true
    t.boolean "compound", default: false
    t.float "amount", default: 0.0
    t.boolean "active", default: true
    t.integer "currency_id"
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.float "price", default: 0.0
    t.boolean "notional_compound", default: true
    t.boolean "only_common_expenses", default: true
    t.integer "rate_type", default: 0
    t.boolean "fixed_daily_interest", default: false
    t.float "minimun_debt", default: 0.0
    t.integer "price_type", default: 0, null: false
    t.index ["community_id"], name: "index_community_interests_on_community_id"
  end

  create_table "community_packages", force: :cascade do |t|
    t.string "name"
    t.float "price"
    t.string "country_code"
    t.integer "package_type"
    t.string "currency_type"
    t.integer "months_to_bill"
    t.integer "invoice_type"
    t.float "exempt_percentage", default: 0.0, null: false
    t.boolean "active", default: true, null: false
    t.string "periodicity"
    t.date "next_billing_date"
    t.integer "community_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "upselling", default: false
    t.bigint "account_id"
    t.integer "price_type", default: 0, null: false
    t.float "minimum_price", default: 0.0, null: false
    t.index ["account_id"], name: "index_community_packages_on_account_id"
  end

  create_table "community_transactions", id: :serial, force: :cascade do |t|
    t.string "account"
    t.integer "community_id"
    t.integer "period_expense_id"
    t.decimal "transaction_value", precision: 19, scale: 4, default: "0.0"
    t.decimal "previous_balance", precision: 19, scale: 4, default: "0.0"
    t.decimal "later_balance", precision: 19, scale: 4, default: "0.0"
    t.integer "origin_id"
    t.string "origin_class"
    t.string "origin_url"
    t.string "comments"
    t.datetime "transaction_date", precision: nil
    t.boolean "paid", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "payment_type"
    t.integer "state_id", default: 0
    t.boolean "confirmed", default: false
    t.datetime "accountable_date", precision: nil
    t.boolean "issued", default: false
    t.string "name"
    t.integer "folio"
    t.string "description"
    t.boolean "custom", default: false
    t.boolean "closed", default: false
    t.integer "transaction_period_expense_id"
    t.string "document_number"
    t.datetime "expiration_date", precision: nil
    t.datetime "payment_date", precision: nil
    t.bigint "bank_account_id"
    t.boolean "is_initial_balance", default: false
    t.boolean "is_balance_reconciliation", default: false
    t.integer "bank_transaction_id"
    t.index ["bank_account_id"], name: "index_community_transactions_on_bank_account_id"
    t.index ["community_id"], name: "index_community_transactions_on_community_id"
    t.index ["origin_id"], name: "index_community_transactions_on_origin_id"
    t.index ["period_expense_id"], name: "index_community_transactions_on_period_expense_id"
  end

  create_table "community_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_code"
    t.boolean "active"
    t.integer "community_id"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "position"
    t.integer "server_user_group_id"
    t.index ["community_id"], name: "index_community_users_on_community_id"
    t.index ["user_id"], name: "index_community_users_on_user_id"
  end

  create_table "companion_guests", force: :cascade do |t|
    t.bigint "guest_registry_id"
    t.string "cid"
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.index ["guest_registry_id"], name: "index_companion_guests_on_guest_registry_id"
  end

  create_table "comunas", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "region_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "conferences", force: :cascade do |t|
    t.timestamptz "event_start", null: false
    t.timestamptz "event_end", null: false
    t.string "videochat_url"
    t.string "calendar_url"
    t.string "calendar_event_id"
    t.integer "post_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["post_id"], name: "index_conferences_on_post_id"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "position"
    t.integer "community_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.integer "community_id"
    t.datetime "pdf_document_updated_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pdf_document"
  end

  create_table "currencies", id: :serial, force: :cascade do |t|
    t.text "name"
    t.float "value"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "customer_success_settings", force: :cascade do |t|
    t.text "comments"
    t.string "hubspot_link"
    t.string "initial_portfolio_executive"
    t.string "sales_executive"
    t.string "stable_portfolio_executive"
    t.bigint "community_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "particular_use", default: false
    t.boolean "preinstalled", default: false
    t.string "commission_month"
    t.index ["community_id"], name: "index_customer_success_settings_on_community_id"
  end

  create_table "data_scrapers", id: :serial, force: :cascade do |t|
    t.datetime "day", precision: nil
    t.text "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "debit_recurrences", force: :cascade do |t|
    t.string "name"
    t.integer "periodicity"
    t.date "debit_date"
    t.string "distribution"
    t.bigint "fund_id"
    t.text "description"
    t.decimal "value"
    t.jsonb "value_by_property"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "aliquot_id"
    t.bigint "community_id", null: false
    t.bigint "creator_id", null: false
    t.string "assignment_type"
    t.boolean "active", default: true
    t.boolean "date_in_name"
    t.jsonb "deduction_groups"
    t.date "latest_creation"
    t.date "next_creation"
    t.index ["aliquot_id"], name: "index_debit_recurrences_on_aliquot_id"
    t.index ["community_id"], name: "index_debit_recurrences_on_community_id"
    t.index ["creator_id"], name: "index_debit_recurrences_on_creator_id"
    t.index ["fund_id"], name: "index_debit_recurrences_on_fund_id"
  end

  create_table "debts", id: :serial, force: :cascade do |t|
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.decimal "money_paid", precision: 19, scale: 4, default: "0.0"
    t.decimal "money_balance", precision: 19, scale: 4, default: "0.0"
    t.boolean "paid", default: false
    t.datetime "priority_date", precision: nil
    t.integer "property_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "common", default: false
    t.bigint "common_expense_id"
    t.datetime "last_interest_bill_date", precision: nil
    t.string "description"
    t.integer "reference_id"
    t.boolean "custom", default: false
    t.integer "excel_upload_id"
    t.integer "origin_id"
    t.string "origin_type"
    t.index "EXTRACT(year FROM priority_date)", name: "index_debts_on_EXTRACT_YEAR_FROM_priority_date"
    t.index ["common_expense_id"], name: "index_debts_on_common_expense_id"
    t.index ["origin_id", "origin_type"], name: "index_debts_on_origin_id_and_origin_type"
    t.index ["priority_date"], name: "index_debts_on_priority_date"
    t.index ["property_id"], name: "index_debts_on_property_id"
  end

  create_table "deduction_groups", force: :cascade do |t|
    t.integer "property_fine_group_id"
    t.integer "discount_type"
    t.string "name"
    t.decimal "percentage", precision: 5, scale: 2
    t.decimal "price", precision: 22, scale: 2
    t.datetime "valid_until", precision: nil
    t.index ["property_fine_group_id"], name: "index_deduction_groups_on_property_fine_group_id"
  end

  create_table "deductions", force: :cascade do |t|
    t.integer "debt_id"
    t.boolean "active"
    t.boolean "applied"
    t.integer "discount_type"
    t.string "name"
    t.decimal "percentage", precision: 5, scale: 2
    t.decimal "price", precision: 22, scale: 2
    t.datetime "valid_until", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "deduction_group_id"
    t.index ["debt_id"], name: "index_deductions_on_debt_id"
    t.index ["deduction_group_id"], name: "index_deductions_on_deduction_group_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue", default: "low_ram"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "comments"
    t.integer "community_id"
    t.string "job_name"
    t.index ["community_id"], name: "index_delayed_jobs_on_community_id"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "discounts", id: :serial, force: :cascade do |t|
    t.float "percentage", default: 0.0, null: false
    t.string "name", default: ""
    t.boolean "active", default: true, null: false
    t.integer "discount_type", default: 0, null: false
    t.datetime "initial_date", precision: nil
    t.datetime "expiration_date", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "period_expense_id"
    t.datetime "start_date", precision: nil
    t.index ["period_expense_id"], name: "index_discounts_on_period_expense_id"
  end

  create_table "discounts_drafts", force: :cascade do |t|
    t.integer "days", default: 0
    t.integer "hours", default: 0
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dispersed_payments", force: :cascade do |t|
    t.bigint "payment_id"
    t.integer "transaction_id"
    t.datetime "dispersion_date", precision: nil
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "intend", default: 1
    t.integer "status", default: 1
    t.json "metadata", default: []
    t.bigint "community_id"
    t.index ["community_id"], name: "index_dispersed_payments_on_community_id"
    t.index ["payment_id"], name: "index_dispersed_payments_on_payment_id"
  end

  create_table "document_stats", force: :cascade do |t|
    t.string "document"
    t.integer "community_id"
    t.integer "user_id"
    t.string "role"
    t.string "data"
    t.boolean "success"
    t.index ["community_id"], name: "index_document_stats_on_community_id"
    t.index ["user_id"], name: "index_document_stats_on_user_id"
  end

  create_table "email_links", force: :cascade do |t|
    t.datetime "expiration_date", precision: nil, default: -> { "(CURRENT_TIMESTAMP + 'P2D'::interval)" }
    t.datetime "entry_date", precision: nil
    t.datetime "mailing_date", precision: nil
    t.datetime "payment_date", precision: nil
    t.string "email"
    t.string "link"
    t.string "token"
    t.string "subject_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "bill_id"
  end

  create_table "employees", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "rut"
    t.datetime "born_at", precision: nil
    t.string "position"
    t.datetime "photo_updated_at", precision: nil
    t.integer "community_id"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "phone"
    t.string "email"
    t.string "father_last_name"
    t.string "mother_last_name"
    t.string "first_name"
    t.string "citizenship"
    t.string "sexo"
    t.string "foreign_citizenship"
    t.string "comuna_id"
    t.string "region_id"
    t.string "address"
    t.string "rut_afiliado"
    t.string "spouse_father_name"
    t.string "spouse_mother_name"
    t.string "spouse_first_name"
    t.string "photo"
    t.string "importer_type"
    t.integer "importer_id"
    t.index ["community_id"], name: "index_employees_on_community_id"
    t.index ["importer_type", "importer_id"], name: "index_employees_on_importer_type_and_importer_id"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.string "note"
    t.datetime "start_at", precision: nil
    t.datetime "end_at", precision: nil
    t.integer "property_id"
    t.integer "common_space_id"
    t.boolean "confirmed", default: false
    t.boolean "active", default: true
    t.integer "property_fine_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "tag"
    t.boolean "rejected", default: false
    t.datetime "notified_at", precision: nil
    t.integer "user_id"
    t.integer "reservation_user_id"
    t.integer "period_of_charge_id"
    t.boolean "from_web", default: true
  end

  create_table "excel_uploads", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "community_id"
    t.text "error"
    t.datetime "excel_updated_at", precision: nil
    t.boolean "imported", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "uploaded_by"
    t.boolean "admin", default: false
    t.boolean "unsafe_import", default: false
    t.boolean "with_creation", default: false
    t.datetime "result_updated_at", precision: nil
    t.string "excel"
    t.string "result"
    t.datetime "cancelled_at", precision: nil
    t.integer "cancel_user_id"
  end

  create_table "fee_groups", id: :serial, force: :cascade do |t|
    t.string "fee_grouped_id"
    t.string "fee_type"
    t.integer "fee_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["fee_grouped_id", "fee_type", "fee_id"], name: "index_fee_grouped_id_and_fee_type_id"
  end

  create_table "feriados", id: :serial, force: :cascade do |t|
    t.datetime "day", precision: nil
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "fines", id: :serial, force: :cascade do |t|
    t.integer "creator_id"
    t.string "title"
    t.text "content"
    t.float "amount"
    t.boolean "is_fine", default: false
    t.integer "currency_id"
    t.integer "community_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "active", default: true
    t.boolean "not_in_bill", default: false
    t.index ["community_id"], name: "index_fines_on_community_id"
  end

  create_table "finiquito_discounts", id: :serial, force: :cascade do |t|
    t.integer "finiquito_id"
    t.float "amount"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["finiquito_id"], name: "index_finiquito_discounts_on_finiquito_id"
  end

  create_table "finiquitos", id: :serial, force: :cascade do |t|
    t.integer "causal", default: 0
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.integer "worked_days", default: 0
    t.integer "year_service", default: 0
    t.integer "year_holidays", default: 15
    t.float "used_holidays", default: 0.0
    t.integer "dias_inhabiles", default: 0
    t.integer "base_salary", default: 0
    t.integer "avg_commisions", default: 0
    t.integer "avg_bonus", default: 0
    t.integer "pagar_indem_aviso_previo", default: 0
    t.integer "transportation_benefit", default: 0
    t.integer "lunch_benefit", default: 0
    t.integer "advance_gratifications", default: 0
    t.integer "otros_no_imponibles", default: 0
    t.integer "special_bonus", default: 0
    t.integer "discount_days", default: 0
    t.integer "day_value_for_pending_month", default: 0
    t.integer "work_days_pending_month", default: 0
    t.integer "extra_hour", default: 0
    t.integer "monto_horas_extra", default: 0
    t.integer "advance", default: 0
    t.integer "legal_holds", default: 0
    t.integer "lost_cash_allocation", default: 0
    t.integer "allocation_tool_wear", default: 0
    t.integer "refund", default: 0
    t.integer "viaticum", default: 0
    t.integer "commisions", default: 0
    t.integer "bonus", default: 0
    t.integer "total_indemnification", default: 0
    t.integer "total_indemnification_forewarned", default: 0
    t.integer "pending_last_salary", default: 0
    t.integer "indemnification_fuero_maternal", default: 0
    t.integer "feriado_proporcional", default: 0
    t.integer "prepago_ccaf", default: 0
    t.integer "total_finiquito", default: 0
    t.integer "salary_id"
    t.integer "employee_id"
    t.text "pdf_value"
    t.integer "period_expense_id"
    t.integer "aliquot_id", default: 0
    t.boolean "nullified", default: false
    t.datetime "nullified_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "document_updated_at", precision: nil
    t.datetime "sign_date", precision: nil
    t.integer "fuero_maternal", default: 0
    t.integer "indemnizacion_acordada", default: 0
    t.integer "salary_one_month_ago", default: 0
    t.integer "salary_two_month_ago", default: 0
    t.integer "salary_three_month_ago", default: 0
    t.integer "last_monthly_gratifications", default: 0
    t.integer "last_month_viatico", default: 0
    t.integer "last_month_lost_cash_allocation", default: 0
    t.integer "last_month_allocation_tool_wear", default: 0
    t.integer "last_month_transportation_benefit", default: 0
    t.integer "last_month_lunch_benefit", default: 0
    t.integer "last_month_special_bonus", default: 0
    t.integer "utilizado_anos_servicio_y_mes_aviso", default: 0
    t.integer "utilizado_feriado_proporcional", default: 0
    t.boolean "apply_to_common_expense", default: true
    t.float "unused_holidays", default: 0.0
    t.integer "monto_horas_extra_2", default: 0
    t.integer "extra_hour_2", default: 0
    t.integer "monto_horas_extra_3", default: 0
    t.integer "extra_hour_3", default: 0
    t.integer "service_billing_id"
    t.text "first_content", default: ""
    t.text "last_content", default: ""
    t.datetime "pdf_updated_at", precision: nil
    t.boolean "validated", default: false
    t.integer "fund_id"
    t.integer "nullified_by"
    t.boolean "withholding_for_alimony", default: false
    t.float "withholding_for_alimony_amount"
    t.string "document"
    t.string "pdf"
    t.boolean "invalid_discounts", default: false
    t.index ["service_billing_id"], name: "index_finiquitos_on_service_billing_id"
  end

  create_table "finkok_response_payments", force: :cascade do |t|
    t.bigint "payment_id"
    t.bigint "finkok_response_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["finkok_response_id"], name: "index_finkok_response_payments_on_finkok_response_id"
    t.index ["payment_id"], name: "index_finkok_response_payments_on_payment_id"
  end

  create_table "finkok_responses", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.string "sat_seal"
    t.string "no_certificado_sat"
    t.text "xml"
    t.integer "payment_id"
    t.string "cadena_original"
    t.string "company_seal"
    t.string "company_rfc"
    t.string "company_certificate_number"
    t.datetime "irs_at", precision: nil
    t.string "receptor_rfc"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "fiscal_regime"
    t.boolean "success", default: false
    t.string "error_description"
    t.string "error_code"
    t.boolean "cancelled", default: false
    t.string "estatus_uuid"
    t.string "estatus_cancelacion"
    t.datetime "cancelled_at", precision: nil
    t.integer "invoice_id"
    t.integer "internal_folio"
    t.string "receptor_name"
    t.string "receptor_uso_cfdi"
    t.float "subtotal", default: 0.0
    t.float "iva", default: 0.0
    t.float "total", default: 0.0
    t.integer "payment_method", default: 0
    t.boolean "generated_pdf", default: false
    t.integer "parent_id"
    t.integer "complement_status", default: 0
    t.datetime "pdf_updated_at", precision: nil
    t.integer "irs_type", default: 0
    t.string "pdf"
    t.string "regimen_fiscal_receptor"
    t.string "domicilio_fiscal_receptor"
    t.boolean "grouped", default: false
    t.string "folio"
    t.bigint "invoice_payment_assignment_id"
    t.string "invoiceable_type"
    t.bigint "invoiceable_id"
    t.index ["invoice_payment_assignment_id"], name: "index_finkok_responses_on_invoice_payment_assignment_id"
    t.index ["invoiceable_id", "invoiceable_type"], name: "index_finkok_responses_on_invoiceable_id_and_invoiceable_type"
    t.index ["invoiceable_type", "invoiceable_id"], name: "index_finkok_responses_on_invoiceable"
    t.index ["parent_id"], name: "index_finkok_responses_on_parent_id"
    t.index ["payment_id"], name: "index_finkok_responses_on_payment_id"
  end

  create_table "fiscal_identifications", force: :cascade do |t|
    t.string "fiscal_identifiable_type"
    t.bigint "fiscal_identifiable_id"
    t.string "postal_code"
    t.string "fiscal_regime"
    t.string "cfdi_use"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["fiscal_identifiable_type", "fiscal_identifiable_id"], name: "index_fiscal_identifications_on_fiscal_identifiable"
  end

  create_table "folios", id: :serial, force: :cascade do |t|
    t.integer "community_id", null: false
    t.string "folio_type", null: false
    t.integer "folio", default: 0, null: false
    t.boolean "locked", default: false, null: false
    t.index ["community_id", "folio_type"], name: "index_folios_on_folio_type_and_community_id"
  end

  create_table "fonasa_distributions", force: :cascade do |t|
    t.date "start_date"
    t.float "fonasa_percentage"
    t.float "ccaf_percentage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "free_debt_certificate_settings", force: :cascade do |t|
    t.text "message"
    t.bigint "community_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_free_debt_certificate_settings_on_community_id"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "fund_movements", id: :serial, force: :cascade do |t|
    t.integer "period_expense_id"
    t.integer "fund_id"
    t.integer "origin_id"
    t.integer "origin_type"
    t.float "price"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "not_in_bill", default: true
    t.index ["origin_id", "origin_type"], name: "index_fund_movements_on_origin_id_and_origin_type"
  end

  create_table "fund_period_expenses", id: :serial, force: :cascade do |t|
    t.float "previous_balance", default: 0.0
    t.float "later_balance", default: 0.0
    t.float "price", default: 0.0
    t.integer "period_expense_id"
    t.integer "fund_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "fund_transfers", id: :serial, force: :cascade do |t|
    t.integer "income_id"
    t.integer "service_billing_id"
    t.integer "community_id"
    t.float "amount"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "funds", id: :serial, force: :cascade do |t|
    t.integer "community_id"
    t.decimal "price", precision: 19, scale: 4
    t.boolean "active", default: true
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "fund_type", default: 1
    t.decimal "initial_price", precision: 19, scale: 4, default: "0.0"
    t.boolean "to_invest", default: false
    t.boolean "is_reserve_fund", default: false
    t.float "percentage", default: 0.0
    t.integer "aliquot_id"
    t.boolean "show_service_billings_in_bill", default: false
    t.boolean "exclusive", default: false
    t.index ["aliquot_id"], name: "index_funds_on_aliquot_id"
    t.index ["community_id"], name: "index_funds_on_community_id"
  end

  create_table "future_statements", force: :cascade do |t|
    t.integer "bill_id"
    t.integer "property_id"
    t.float "discount", default: 0.0
    t.integer "period_expense_id"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "discount_type", default: 0
  end

  create_table "guest_entries", force: :cascade do |t|
    t.bigint "guest_registry_id"
    t.integer "entry_type"
    t.datetime "time_log", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["guest_registry_id"], name: "index_guest_entries_on_guest_registry_id"
  end

  create_table "guest_registries", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "rut"
    t.integer "property_id"
    t.string "registration_plate"
    t.string "comment"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "folio", default: 0
    t.datetime "registered_at", precision: nil
    t.string "parking_lot"
    t.datetime "leave_at", precision: nil
    t.string "sex"
    t.boolean "foreign", default: false
    t.boolean "manual", default: true
    t.boolean "attended", default: true
    t.boolean "from_guest_list", default: false
    t.bigint "excel_upload_id"
    t.bigint "nullifier_id"
    t.string "token"
    t.datetime "estimated_leaving_date", precision: nil
    t.string "email"
    t.string "phone"
    t.integer "guest_type", default: 0, null: false
    t.bigint "community_id"
    t.boolean "rejected", default: false
    t.index ["community_id"], name: "index_guest_registries_on_community_id"
    t.index ["excel_upload_id"], name: "index_guest_registries_on_excel_upload_id"
    t.index ["nullifier_id"], name: "index_guest_registries_on_nullifier_id"
    t.index ["property_id"], name: "index_guest_registries_on_property_id"
  end

  create_table "guides", id: :serial, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.integer "first_task_id"
  end

  create_table "happy_suppliers_settings", force: :cascade do |t|
    t.boolean "active", default: false
    t.string "url", default: "https://www.administradoresmexico.mx/proveedores", null: false
    t.bigint "community_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_happy_suppliers_settings_on_community_id"
  end

  create_table "identifications", id: :serial, force: :cascade do |t|
    t.string "identity"
    t.string "identity_type"
    t.string "identificable_type"
    t.integer "identificable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["identificable_id", "identity_type", "identificable_type"], name: "index_identificable_id_and_identificable_type"
  end

  create_table "importers", force: :cascade do |t|
    t.integer "community_id", null: false
    t.boolean "imported", default: false, null: false
    t.string "importer_type", null: false
    t.string "importer_origin", null: false
    t.integer "imported_by"
    t.text "results"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_importers_on_community_id"
    t.index ["imported_by"], name: "index_importers_on_imported_by"
  end

  create_table "inactive_communities", id: :serial, force: :cascade do |t|
    t.integer "community_id"
    t.integer "days_since_last_generation"
    t.integer "days_since_last_service_billing"
    t.integer "days_since_last_payment"
    t.boolean "is_billed"
    t.boolean "is_paid"
    t.datetime "date_reported", precision: nil
    t.integer "risk_range"
    t.string "administrator_name"
    t.string "administrator_phone"
    t.string "administrator_email"
    t.string "community_email"
    t.string "community_phone"
    t.string "community_name"
    t.integer "generated_periods_count"
    t.string "last_generated_period"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_inactive_communities_on_community_id"
    t.index ["date_reported"], name: "index_inactive_communities_on_date_reported"
  end

  create_table "incomes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.decimal "price", precision: 19, scale: 4
    t.integer "period_expense_id"
    t.boolean "to_discount"
    t.text "note"
    t.datetime "receipt_updated_at", precision: nil
    t.datetime "documentation_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.date "paid_at"
    t.integer "aliquot_id"
    t.boolean "after_funds", default: false
    t.integer "folio", default: 0
    t.boolean "paid", default: true
    t.string "document_number"
    t.integer "payment_type", default: 0
    t.integer "fund_id", default: -1
    t.boolean "active", default: true
    t.integer "excel_upload_id"
    t.boolean "include_in_bank_reconciliation", default: true
    t.string "documentation"
    t.string "receipt"
    t.string "importer_type"
    t.integer "importer_id"
    t.index ["importer_type", "importer_id"], name: "index_incomes_on_importer_type_and_importer_id"
    t.index ["period_expense_id"], name: "index_incomes_on_period_expense_id"
  end

  create_table "installations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "community_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.index ["community_id"], name: "index_installations_on_community_id"
  end

  create_table "integration_settings", id: :serial, force: :cascade do |t|
    t.integer "integration_id"
    t.string "value"
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["integration_id"], name: "index_integration_settings_on_integration_id"
  end

  create_table "integrations", id: :serial, force: :cascade do |t|
    t.integer "community_id"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_integrations_on_community_id"
  end

  create_table "interests", id: :serial, force: :cascade do |t|
    t.decimal "base_price", precision: 19, scale: 4, default: "0.0"
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.integer "community_interest_id"
    t.integer "origin_debt_id"
    t.integer "period_expense_id"
    t.integer "debt_id"
    t.integer "property_transaction_id"
    t.integer "property_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "common_expense_id"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.string "description"
    t.string "origin_name"
    t.boolean "to_undo", default: false
    t.boolean "custom", default: false
    t.integer "excel_upload_id"
    t.index ["debt_id"], name: "index_interests_on_debt_id"
    t.index ["origin_debt_id"], name: "index_interests_on_origin_debt_id"
    t.index ["period_expense_id"], name: "index_interests_on_period_expense_id"
    t.index ["property_id"], name: "index_interests_on_property_id"
    t.index ["property_transaction_id"], name: "index_interests_on_property_transaction_id"
  end

  create_table "internal_banking_settings", force: :cascade do |t|
    t.string "costs_center"
    t.string "costs_center_name"
    t.string "costs_center_clabe"
    t.string "stp_account_number"
    t.string "payer_tin"
    t.string "payer_name"
    t.bigint "community_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_internal_banking_settings_on_community_id"
  end

  create_table "internal_dispersions", force: :cascade do |t|
    t.bigint "payment_id"
    t.integer "transaction_id"
    t.datetime "dispersion_date", precision: nil
    t.string "description"
    t.integer "status", default: 1
    t.integer "intend", default: 1
    t.bigint "community_id"
    t.bigint "dispersed_payment_id"
    t.string "payment_method"
    t.float "total_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_internal_dispersions_on_community_id"
    t.index ["dispersed_payment_id"], name: "index_internal_dispersions_on_dispersed_payment_id"
    t.index ["payment_id"], name: "index_internal_dispersions_on_payment_id"
  end

  create_table "invoice_lines", id: :serial, force: :cascade do |t|
    t.string "description"
    t.integer "quantity"
    t.integer "pricing_id"
    t.integer "initial_period_expense_id"
    t.integer "final_period_expense_id"
    t.float "unit_price"
    t.float "final_price"
    t.integer "invoice_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "community_id"
    t.boolean "exempt", default: false, null: false
    t.bigint "community_package_id"
  end

  create_table "invoice_payment_assignments", force: :cascade do |t|
    t.bigint "invoice_id"
    t.bigint "invoice_payment_id"
    t.decimal "amount", precision: 19, scale: 4, default: "0.0"
    t.datetime "assigned_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["invoice_id"], name: "index_invoice_payment_assignments_on_invoice_id"
    t.index ["invoice_payment_id"], name: "index_invoice_payment_assignments_on_invoice_payment_id"
  end

  create_table "invoice_payments", id: :serial, force: :cascade do |t|
    t.datetime "paid_at", precision: nil
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.integer "status", default: 0
    t.datetime "receipt_updated_at", precision: nil
    t.datetime "document_updated_at", precision: nil
    t.text "text", default: ""
    t.integer "payment_type", default: 0
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "notified", default: false
    t.datetime "notified_at", precision: nil
    t.boolean "nullified", default: false
    t.boolean "completed", default: false
    t.integer "account_id"
    t.string "document"
    t.string "receipt"
    t.index ["account_id"], name: "index_invoice_payments_on_account_id"
  end

  create_table "invoices", id: :serial, force: :cascade do |t|
    t.string "rut", default: ""
    t.string "business_name", default: ""
    t.string "address", default: ""
    t.string "commune", default: ""
    t.string "city", default: ""
    t.string "activity", default: ""
    t.string "petitioner_rut", default: ""
    t.string "contact_email", default: ""
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.datetime "pdf_updated_at", precision: nil
    t.integer "invoice_payment_id"
    t.integer "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "irs_bill_id"
    t.datetime "irs_billed_at", precision: nil
    t.integer "excel_upload_id"
    t.boolean "irs_billed", default: false
    t.boolean "active", default: false
    t.integer "nubox_id"
    t.boolean "nullified", default: false
    t.string "country", default: "Chile"
    t.boolean "irs_notified", default: false
    t.datetime "expiration_date", precision: nil
    t.boolean "paid", default: false
    t.integer "internal_folio"
    t.string "pdf"
    t.string "irs_external_id"
    t.string "irs_external_service"
  end

  create_table "issues", force: :cascade do |t|
    t.text "description", default: ""
    t.string "category", default: ""
    t.boolean "active", default: true
    t.bigint "user_in_charge_id"
    t.bigint "accountable_id"
    t.bigint "community_id"
    t.bigint "closed_by_id"
    t.bigint "deleted_by_id"
    t.datetime "closed_at", precision: nil
    t.datetime "started_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "comments"
    t.bigint "property_id"
    t.string "title"
    t.index ["accountable_id"], name: "index_issues_on_accountable_id"
    t.index ["closed_by_id"], name: "index_issues_on_closed_by_id"
    t.index ["community_id"], name: "index_issues_on_community_id"
    t.index ["deleted_by_id"], name: "index_issues_on_deleted_by_id"
    t.index ["property_id"], name: "index_issues_on_property_id"
    t.index ["user_in_charge_id"], name: "index_issues_on_user_in_charge_id"
  end

  create_table "leaving_communities", force: :cascade do |t|
    t.text "additional_comments"
    t.date "leaving_date", null: false
    t.date "deactivation_date", null: false
    t.float "associated_value", null: false
    t.string "currency_type", null: false
    t.integer "status", default: 0, null: false
    t.integer "reasons_to_leave", default: [], array: true
    t.integer "community_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_leaving_communities_on_community_id"
    t.index ["reasons_to_leave"], name: "index_leaving_communities_on_reasons_to_leave", using: :gin
    t.index ["user_id"], name: "index_leaving_communities_on_user_id"
  end

  create_table "library_files", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.bigint "downloads_count", default: 0
    t.datetime "document_updated_at", precision: nil
    t.bigint "community_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "document"
    t.string "description"
    t.integer "document_type"
    t.index ["community_id"], name: "index_library_files_on_community_id"
  end

  create_table "license_drafts", force: :cascade do |t|
    t.bigint "salary_payment_draft_id", null: false
    t.integer "days", default: 0
    t.date "start_date"
    t.date "end_date"
    t.integer "ultimo_total_imponible_sin_licencia", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["salary_payment_draft_id"], name: "index_license_drafts_on_salary_payment_draft_id"
  end

  create_table "logbooks", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.string "name"
    t.text "description"
    t.datetime "registered_at", precision: nil
    t.boolean "important", default: false
    t.boolean "active", default: true
    t.integer "folio", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "community_id"
    t.bigint "user_id"
    t.boolean "notified"
    t.bigint "nullifier_id"
    t.index ["nullifier_id"], name: "index_logbooks_on_nullifier_id"
    t.index ["user_id"], name: "index_logbooks_on_user_id"
  end

  create_table "logs", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "community_id"
    t.string "origin_class"
    t.integer "origin_id"
    t.string "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin", default: false
    t.string "from"
    t.index ["community_id"], name: "index_logs_on_community_id"
    t.index ["origin_class"], name: "index_logs_on_origin_class"
    t.index ["user_id"], name: "index_logs_on_user_id"
  end

  create_table "maintenances", id: :serial, force: :cascade do |t|
    t.integer "installation_id"
    t.string "name"
    t.date "scheduled_date"
    t.boolean "completed", default: false
    t.date "completed_at"
    t.text "comments"
    t.text "post_service_comments"
    t.integer "supplier_id"
    t.datetime "task_file_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "task_file_completed_updated_at", precision: nil
    t.boolean "active", default: true
    t.string "task_file"
    t.string "task_file_completed"
    t.index ["installation_id"], name: "index_maintenances_on_installation_id"
  end

  create_table "marks", id: :serial, force: :cascade do |t|
    t.integer "meter_id"
    t.integer "period_expense_id"
    t.float "value"
    t.float "consumed"
    t.float "estimated_cost", default: 0.0
    t.integer "property_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "excel_upload_id"
    t.boolean "restart", default: false
    t.index ["meter_id", "period_expense_id", "property_id"], name: "index_marks_on_meter_id_and_period_expense_id_and_property_id", unique: true
    t.index ["meter_id"], name: "index_marks_on_meter_id"
    t.index ["period_expense_id"], name: "index_marks_on_period_expense_id"
    t.index ["property_id"], name: "index_marks_on_property_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "sender_id"
    t.integer "receiver_id"
    t.string "title"
    t.text "content"
    t.boolean "read", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "meter_periods", id: :serial, force: :cascade do |t|
    t.integer "meter_id"
    t.integer "period_expense_id"
    t.float "unit_price", default: 0.0
    t.boolean "is_fixed", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["meter_id"], name: "index_meter_periods_on_meter_id"
    t.index ["period_expense_id"], name: "index_meter_periods_on_period_expense_id"
  end

  create_table "meters", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.integer "community_id"
    t.string "unit_type", default: "m3"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "description"
    t.float "unit_price", default: 0.0
    t.float "overconsumption_threshold", default: 10.0
    t.index ["community_id"], name: "index_meters_on_community_id"
  end

  create_table "mx_companies", id: :serial, force: :cascade do |t|
    t.string "postal_code"
    t.string "business_name"
    t.string "fiscal_regime"
    t.text "certificate"
    t.string "certificate_number"
    t.string "rfc"
    t.integer "community_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "csd_password"
    t.datetime "expiration_cert", precision: nil
    t.datetime "csd_key_updated_at", precision: nil
    t.datetime "csd_cer_updated_at", precision: nil
    t.datetime "billed_payments_zip_updated_at", precision: nil
    t.string "csd_key"
    t.string "csd_cer"
    t.string "billed_payments_zip"
    t.string "periodicity", default: "01"
    t.string "constancia_situacion_fiscal"
    t.datetime "constancia_situacion_fiscal_updated_at", precision: nil
  end

  create_table "notification_logs", force: :cascade do |t|
    t.integer "notification_type", null: false
    t.jsonb "data"
    t.integer "recipients", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notification_user_logs", force: :cascade do |t|
    t.bigint "notification_log_id", null: false
    t.bigint "user_id", null: false
    t.jsonb "data"
    t.datetime "read_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_log_id"], name: "index_notification_user_logs_on_notification_log_id"
    t.index ["user_id"], name: "index_notification_user_logs_on_user_id"
  end

  create_table "ocr_facturas", id: :serial, force: :cascade do |t|
    t.string "rut"
    t.datetime "bill_at", precision: nil
    t.string "name"
    t.integer "price"
    t.text "ocr_text"
    t.integer "period_expense_id"
    t.integer "service_billing_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "document_number"
  end

  create_table "online_payment_requests", force: :cascade do |t|
    t.string "account_number", null: false
    t.integer "community_id", null: false
    t.string "bank", null: false
    t.string "signer_name", null: false
    t.string "account_email", null: false
    t.enum "status", default: "pending", null: false, enum_type: "request_status"
    t.text "comment"
    t.integer "uploader_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_online_payment_requests_on_community_id"
    t.index ["uploader_id"], name: "index_online_payment_requests_on_uploader_id"
  end

  create_table "options", id: :serial, force: :cascade do |t|
    t.integer "question_id"
    t.string "value"
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "outgoing_mails", id: :serial, force: :cascade do |t|
    t.integer "mail_type"
    t.string "subject", default: ""
    t.string "email_to", default: ""
    t.string "email_from", default: ""
    t.integer "recipient_id"
    t.integer "community_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "recipient_type", default: "User"
    t.string "origin_type"
    t.bigint "origin_id"
    t.index ["community_id"], name: "index_outgoing_mails_on_community_id"
    t.index ["origin_type", "origin_id"], name: "index_outgoing_mails_on_origin_type_and_origin_id"
    t.index ["recipient_id"], name: "index_outgoing_mails_on_recipient_id"
  end

  create_table "package_collaborators", force: :cascade do |t|
    t.integer "collaborator_id"
    t.integer "package_id"
    t.integer "class_type"
    t.string "collaborator_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collaborator_id"], name: "index_package_collaborators_on_collaborator_id"
    t.index ["package_id"], name: "index_package_collaborators_on_package_id"
  end

  create_table "package_limits", force: :cascade do |t|
    t.integer "min_value"
    t.integer "max_value"
    t.integer "limit_type"
    t.string "country_code"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "package_notifications", force: :cascade do |t|
    t.integer "package_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "property_id", null: false
    t.boolean "notified", default: false
    t.index ["package_id"], name: "index_package_notifications_on_package_id"
    t.index ["property_id"], name: "index_package_notifications_on_property_id"
    t.index ["user_id"], name: "index_package_notifications_on_user_id"
  end

  create_table "packages", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "community_id"
    t.datetime "delivered_at", precision: nil
    t.datetime "notified_at", precision: nil
    t.integer "property_id"
    t.string "image"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "image_updated_at", precision: nil
    t.string "deliver_image"
    t.datetime "deliver_image_updated_at", precision: nil
    t.datetime "overdue_notified_at", precision: nil
    t.index ["community_id"], name: "index_packages_on_community_id"
    t.index ["property_id"], name: "index_packages_on_property_id"
  end

  create_table "packages_package_limits", force: :cascade do |t|
    t.bigint "package_limit_id"
    t.string "packageable_type"
    t.bigint "packageable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["package_limit_id"], name: "index_packages_package_limits_on_package_limit_id"
    t.index ["packageable_type", "packageable_id"], name: "index_packageable_id_and_packageable_type"
  end

  create_table "payment_gateway_settings", force: :cascade do |t|
    t.bigint "community_id", null: false
    t.string "commerce_code", null: false
    t.float "credit_commission", null: false
    t.float "debit_commission", null: false
    t.float "phi", null: false
    t.float "delta", null: false
    t.string "affiliated_email"
    t.string "payment_gateway_name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_payment_gateway_settings_on_community_id"
  end

  create_table "payment_portal_settings", force: :cascade do |t|
    t.string "api_token"
    t.boolean "active", default: false
    t.bigint "community_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_payment_portal_settings_on_community_id"
  end

  create_table "payments", id: :serial, force: :cascade do |t|
    t.decimal "price", precision: 19, scale: 4, default: "0.0"
    t.integer "state", default: 1
    t.datetime "receipt_updated_at", precision: nil
    t.boolean "completed", default: false
    t.integer "user_id"
    t.date "paid_at"
    t.datetime "confirmed_at", precision: nil
    t.integer "property_id"
    t.integer "property_transaction_id"
    t.integer "bill_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "payment_type", default: 2
    t.string "payment_number"
    t.boolean "issued", default: false
    t.integer "period_expense_id"
    t.string "description"
    t.boolean "nullified", default: false
    t.datetime "nullified_at", precision: nil
    t.integer "nullified_transaction_id"
    t.boolean "generated_pdf", default: false
    t.boolean "receipt_notified", default: false
    t.datetime "receipt_notified_at", precision: nil
    t.integer "folio"
    t.integer "excel_upload_id"
    t.decimal "temp_money_compensation", precision: 19, scale: 4, default: "0.0"
    t.boolean "compensation", default: false
    t.boolean "undid", default: false
    t.integer "origin_payment_id"
    t.integer "bundle_payment_id"
    t.boolean "to_bill", default: false
    t.boolean "confirmed", default: false
    t.integer "reference_id"
    t.boolean "exported", default: false
    t.string "user_name"
    t.string "user_mail"
    t.boolean "irs_billed", default: false
    t.datetime "irs_billed_at", precision: nil
    t.integer "irs_status", default: 0
    t.boolean "visible", default: true
    t.integer "nullifier_id"
    t.boolean "annual", default: false
    t.boolean "estimate_future_debt", default: true
    t.string "source", default: "form"
    t.boolean "notifying", default: false
    t.bigint "deduction_id"
    t.string "receipt"
    t.string "tracking_number"
    t.string "importer_type"
    t.integer "importer_id"
    t.boolean "assignable_imported"
    t.index ["bill_id"], name: "index_payments_on_bill_id"
    t.index ["deduction_id"], name: "index_payments_on_deduction_id"
    t.index ["importer_type", "importer_id"], name: "index_payments_on_importer_type_and_importer_id"
    t.index ["origin_payment_id"], name: "index_payments_on_origin_payment_id"
    t.index ["period_expense_id"], name: "index_payments_on_period_expense_id"
    t.index ["property_id"], name: "index_payments_on_property_id"
    t.index ["property_transaction_id"], name: "index_payments_on_property_transaction_id"
  end

  create_table "period_expense_registers", id: :serial, force: :cascade do |t|
    t.integer "responsible_id"
    t.integer "period_expense_id"
    t.string "description"
    t.datetime "date", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["period_expense_id"], name: "index_period_expense_registers_on_period_expense_id"
  end

  create_table "period_expenses", id: :serial, force: :cascade do |t|
    t.datetime "period", precision: nil
    t.integer "community_id"
    t.integer "basic_invidual_amount"
    t.decimal "global_amount", precision: 30
    t.boolean "common_expense_generated", default: false
    t.datetime "common_expense_generated_at", precision: nil
    t.datetime "expiration_date", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "initial_setup", default: false
    t.boolean "request_calculate", default: false
    t.boolean "calculate_done", default: true
    t.datetime "calculated_at", precision: nil
    t.datetime "pdf_bills_updated_at", precision: nil
    t.boolean "forced_expiration", default: false
    t.boolean "bill_generated", default: false
    t.datetime "bill_generated_at", precision: nil
    t.boolean "blocked", default: false
    t.boolean "min_pages", default: false
    t.boolean "undid", default: false
    t.datetime "close_interest_date", precision: nil
    t.datetime "pdf_salary_payments_updated_at", precision: nil
    t.datetime "pdf_short_bills_updated_at", precision: nil
    t.float "start_balance", default: 0.0
    t.integer "start_reserve_balance"
    t.integer "end_reserve_balance"
    t.boolean "paid", default: false
    t.boolean "invoiced", default: false
    t.boolean "notified", default: false
    t.boolean "enable", default: true
    t.boolean "first_bank_reconciliation", default: false
    t.boolean "bank_reconciliation_closed", default: false
    t.datetime "bank_reconciliation_closed_at", precision: nil
    t.float "uf_value", default: 26000.0
    t.datetime "pdf_grouped_bills_updated_at", precision: nil
    t.datetime "pdf_advances_updated_at", precision: nil
    t.datetime "pdf_payment_receipts_updated_at", precision: nil
    t.datetime "pdf_mixed_bills_updated_at", precision: nil
    t.datetime "bank_reconciliation_voucher_updated_at", precision: nil
    t.datetime "last_recalculate_date", precision: nil
    t.datetime "bill_notified_at", precision: nil
    t.string "bank_reconciliation_voucher"
    t.string "pdf_bills"
    t.string "pdf_salary_payments"
    t.string "pdf_advances"
    t.string "pdf_payment_receipts"
    t.string "pdf_short_bills"
    t.string "pdf_grouped_bills"
    t.string "pdf_mixed_bills"
    t.float "account_balance", default: 0.0
    t.boolean "closed_by_user", default: false
    t.index "EXTRACT(year FROM period)", name: "index_period_expenses_on_EXTRACT_year_FROM_period"
    t.index ["community_id"], name: "index_period_expenses_on_community_id"
    t.index ["period"], name: "index_period_expenses_on_period"
  end

  create_table "periodic_online_payment_executions", force: :cascade do |t|
    t.bigint "periodic_online_payment_id"
    t.bigint "purchase_order_payment_id"
    t.string "status"
    t.string "error_number"
    t.string "error_cause"
    t.bigint "card_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "purchase_order_id"
    t.index ["periodic_online_payment_id"], name: "index_pope_id"
    t.index ["purchase_order_id"], name: "index_periodic_online_payment_executions_on_purchase_order_id"
    t.index ["purchase_order_payment_id"], name: "index_pup_id"
  end

  create_table "periodic_online_payments", force: :cascade do |t|
    t.bigint "property_id"
    t.bigint "user_id"
    t.bigint "external_card_id"
    t.bigint "external_payment_gateway_id"
    t.integer "max_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "document_url"
    t.index ["property_id"], name: "index_periodic_online_payments_on_property_id"
    t.index ["user_id"], name: "index_periodic_online_payments_on_user_id"
  end

  create_table "permissions", id: :serial, force: :cascade do |t|
    t.integer "value", default: 0, null: false
    t.string "code"
    t.integer "community_user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["community_user_id"], name: "index_permissions_on_community_user_id"
  end

  create_table "points", force: :cascade do |t|
    t.float "offset_x"
    t.float "offset_y"
    t.string "path"
    t.bigint "user_id"
    t.bigint "community_id"
    t.string "click_type"
    t.text "xpath"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_type"
    t.index ["community_id"], name: "index_points_on_community_id"
    t.index ["user_id"], name: "index_points_on_user_id"
  end

  create_table "post_templates", force: :cascade do |t|
    t.bigint "community_id"
    t.string "title"
    t.text "body"
    t.string "attached_file"
    t.datetime "attached_file_updated_at", precision: nil
    t.string "pdf"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "pdf_updated_at", precision: nil
    t.string "country_code"
    t.index ["community_id"], name: "index_post_templates_on_community_id"
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.datetime "file_updated_at", precision: nil
    t.integer "community_id"
    t.integer "user_id"
    t.boolean "active", default: true
    t.boolean "published", default: false
    t.boolean "send_by_email", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "recipients"
    t.string "file"
    t.bigint "post_template_id"
    t.boolean "admin", default: true, null: false
    t.boolean "sent_to_all_community", default: false
    t.string "sent_to"
    t.index ["community_id"], name: "index_posts_on_community_id"
    t.index ["post_template_id"], name: "index_posts_on_post_template_id"
  end

  create_table "previred_scrapers", force: :cascade do |t|
    t.date "date"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pricings", id: :serial, force: :cascade do |t|
    t.string "name"
    t.float "value"
    t.integer "months", default: 1
    t.integer "package", default: 0
    t.boolean "public", default: false
    t.boolean "uf", default: true
    t.boolean "has_rem", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.float "exempt_percentage", default: 0.0, null: false
  end

  create_table "product_payments", id: :serial, force: :cascade do |t|
    t.integer "payment_type", default: 0
    t.float "price", default: 0.0
    t.integer "quantity", default: 1
    t.integer "status", default: 0
    t.boolean "paid", default: false
    t.datetime "paid_at", precision: nil
    t.datetime "receipt_updated_at", precision: nil
    t.integer "product_id"
    t.string "user_name"
    t.string "user_mail"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "receipt"
    t.index ["product_id"], name: "index_product_payments_on_product_id"
  end

  create_table "products", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.float "price", default: 0.0
    t.boolean "active", default: true
    t.datetime "document_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "public", default: false
    t.boolean "uf", default: false
    t.string "document"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "community_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.string "country_code"
    t.index ["community_id"], name: "index_profiles_on_community_id"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "properties", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.text "description"
    t.float "size", default: 0.0
    t.integer "community_id"
    t.integer "balance_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "visible", default: true
    t.integer "tower_id"
    t.float "tower_size", default: 0.0
    t.boolean "active", default: true
    t.integer "excel_upload_id"
    t.integer "priority_order", default: 0
    t.boolean "has_reserve_fund", default: true
    t.boolean "print", default: true
    t.boolean "old", default: false
    t.integer "reference_id"
    t.string "alphanumeric_code"
    t.boolean "pays_interests", default: true
    t.datetime "last_defaulting_letter_download_date", precision: nil
    t.string "clabe"
    t.datetime "debts_notified_at", precision: nil
    t.boolean "automatic_payment", default: false
    t.string "importer_type"
    t.integer "importer_id"
    t.index ["balance_id"], name: "index_properties_on_balance_id"
    t.index ["clabe"], name: "index_properties_on_clabe", unique: true
    t.index ["community_id"], name: "index_properties_on_community_id"
    t.index ["importer_type", "importer_id"], name: "index_properties_on_importer_type_and_importer_id"
  end

  create_table "property_account_statement_settings", force: :cascade do |t|
    t.bigint "community_id"
    t.integer "day_of_month", default: 5
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_property_account_statement_settings_on_community_id"
  end

  create_table "property_account_statements", force: :cascade do |t|
    t.bigint "property_id"
    t.datetime "pdf_statement_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "personalized", default: false, null: false
    t.datetime "notified_at", precision: nil
    t.decimal "amount_charged", precision: 19, scale: 4
    t.integer "folio", default: 0
    t.string "pdf_statement"
    t.index ["property_id"], name: "index_property_account_statements_on_property_id"
  end

  create_table "property_aliquots", id: :serial, force: :cascade do |t|
    t.integer "aliquot_id", null: false
    t.integer "property_id", null: false
    t.float "size", default: 0.0
    t.boolean "subproperty", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["aliquot_id"], name: "index_property_aliquots_on_aliquot_id"
    t.index ["property_id"], name: "index_property_aliquots_on_property_id"
  end

  create_table "property_fine_group_discounts", force: :cascade do |t|
    t.string "name"
    t.integer "discount_type", null: false
    t.float "value", default: 0.0, null: false
    t.integer "days_to_activate", default: 0, null: false
    t.bigint "property_fine_group_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["property_fine_group_id"], name: "index_property_fine_group_discounts_on_property_fine_group_id"
  end

  create_table "property_fine_group_surcharges", force: :cascade do |t|
    t.string "name"
    t.integer "surcharge_type", null: false
    t.float "value", default: 0.0, null: false
    t.integer "days_to_activate", default: 0, null: false
    t.bigint "property_fine_group_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["property_fine_group_id"], name: "index_property_fine_group_surcharges_on_property_fine_group_id"
  end

  create_table "property_fine_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "fined_at", precision: nil, null: false
    t.integer "assignment_type", default: 1, null: false
    t.integer "distribution", default: 1, null: false
    t.float "value", default: 0.0, null: false
    t.bigint "community_id", null: false
    t.bigint "aliquot_id"
    t.bigint "fund_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.string "origin_type"
    t.bigint "origin_id"
    t.bigint "period_expense_id"
    t.text "description"
    t.bigint "debit_recurrence_id"
    t.index ["aliquot_id"], name: "index_property_fine_groups_on_aliquot_id"
    t.index ["community_id"], name: "index_property_fine_groups_on_community_id"
    t.index ["debit_recurrence_id"], name: "index_property_fine_groups_on_debit_recurrence_id"
    t.index ["fund_id"], name: "index_property_fine_groups_on_fund_id"
    t.index ["origin_type", "origin_id"], name: "index_property_fine_groups_on_origin_type_and_origin_id"
    t.index ["period_expense_id"], name: "index_property_fine_groups_on_period_expense_id"
  end

  create_table "property_fines", id: :serial, force: :cascade do |t|
    t.integer "creator_id"
    t.integer "property_id"
    t.integer "community_id"
    t.string "title"
    t.text "description"
    t.integer "amount"
    t.decimal "price", precision: 19, scale: 4
    t.string "string_price"
    t.integer "fine_id"
    t.integer "period_expense_id"
    t.boolean "paid", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "unit_price", precision: 19, scale: 4
    t.boolean "issued", default: false
    t.boolean "not_in_bill", default: false
    t.integer "excel_upload_id"
    t.integer "fund_id", default: 0
    t.date "fined_at"
    t.boolean "active", default: true
    t.boolean "all_properties"
    t.boolean "generate_interest", default: false
    t.boolean "independent", default: false
    t.datetime "start_interest_bill_date", precision: nil
    t.bigint "property_fine_group_id"
    t.index ["active", "not_in_bill", "independent", "community_id"], name: "idx_property_fines_covering"
    t.index ["community_id", "fined_at"], name: "index_property_fines_on_community_id_and_fined_at"
    t.index ["fund_id"], name: "index_property_fines_on_fund_id"
    t.index ["period_expense_id"], name: "index_property_fines_on_period_expense_id"
    t.index ["property_fine_group_id"], name: "index_property_fines_on_property_fine_group_id"
    t.index ["property_id"], name: "index_property_fines_on_property_id"
  end

  create_table "property_params", id: :serial, force: :cascade do |t|
    t.integer "community_id"
    t.string "name"
    t.boolean "active", default: true
    t.boolean "in_bill", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "searchable", default: false
  end

  create_table "property_transfers", id: :serial, force: :cascade do |t|
    t.integer "transfer_id", null: false
    t.integer "property_id", null: false
    t.float "old_size", default: 0.0
    t.float "temp_size", default: 0.0
    t.float "new_size", default: 0.0
    t.boolean "active", default: true
    t.boolean "subproperty", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "created", default: false
    t.integer "size_type", default: 0
    t.integer "aliquot_id"
  end

  create_table "property_user_requests", force: :cascade do |t|
    t.integer "property_id"
    t.integer "user_id"
    t.boolean "confirmed"
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.datetime "admin_response_date", precision: nil
    t.string "role", default: "lessee", null: false
    t.boolean "automatic", default: false
    t.index ["property_id"], name: "index_property_user_requests_on_property_id"
    t.index ["user_id"], name: "index_property_user_requests_on_user_id"
  end

  create_table "property_user_validations", force: :cascade do |t|
    t.bigint "property_user_id", null: false
    t.boolean "confirmed"
    t.boolean "active", default: true, null: false
    t.jsonb "reject_reasons", default: {}, null: false
    t.string "ownership_document"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "ownership_document_updated_at", precision: nil
    t.index ["property_user_id"], name: "index_property_user_validations_on_property_user_id"
  end

  create_table "property_users", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "property_id"
    t.boolean "active", default: true
    t.boolean "in_charge", default: false
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "excel_upload_id"
    t.boolean "grouped_bills", default: false
    t.string "group_name", default: "Grupo"
    t.datetime "custom_start_date", precision: nil
    t.datetime "custom_end_date", precision: nil
    t.string "role", default: "lessee"
    t.string "importer_type"
    t.integer "importer_id"
    t.boolean "access_control_enabled"
    t.index ["access_control_enabled"], name: "index_property_users_on_access_control_enabled", where: "(active = true)"
    t.index ["importer_type", "importer_id"], name: "index_property_users_on_importer_type_and_importer_id"
    t.index ["property_id"], name: "index_property_users_on_property_id"
    t.index ["role"], name: "index_property_users_on_role"
    t.index ["user_id"], name: "index_property_users_on_user_id"
  end

  create_table "property_values", id: :serial, force: :cascade do |t|
    t.integer "property_param_id"
    t.integer "property_id"
    t.string "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.boolean "searchable", default: false
  end

  create_table "provision_period_expenses", id: :serial, force: :cascade do |t|
    t.integer "period_expense_id"
    t.integer "provision_id"
    t.float "price", default: 0.0
    t.boolean "issued", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "provision_type", default: 0
    t.index ["period_expense_id"], name: "index_provision_period_expenses_on_period_expense_id"
    t.index ["provision_id"], name: "index_provision_period_expenses_on_provision_id"
  end

  create_table "provisions", id: :serial, force: :cascade do |t|
    t.integer "community_id"
    t.float "goal"
    t.integer "months", default: 1
    t.boolean "completed", default: false
    t.boolean "active", default: true
    t.integer "period_expense_id"
    t.string "name"
    t.boolean "blocked", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "slug"
    t.integer "provision_type", default: 0
    t.integer "aliquot_id"
    t.integer "excel_upload_id"
    t.index ["community_id"], name: "index_provisions_on_community_id"
  end

  create_table "purchase_order_payments", id: :serial, force: :cascade do |t|
    t.integer "external_id", null: false
    t.integer "purchase_order_id"
    t.string "payable_type"
    t.integer "payable_id"
    t.integer "status"
    t.string "payment_method"
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.integer "internal_commission_cents", default: 0, null: false
    t.string "internal_commission_currency", default: "USD", null: false
    t.integer "external_commission_cents", default: 0, null: false
    t.string "external_commission_currency", default: "USD", null: false
    t.integer "total_cents", default: 0, null: false
    t.string "total_currency", default: "USD", null: false
    t.string "currency_code"
    t.string "transaction_code"
    t.datetime "transaction_date", precision: nil
    t.integer "payment_type"
    t.integer "installment_payment_type"
    t.string "card_number"
    t.integer "shares_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "dispertion_id"
    t.bigint "internal_dispersion_id"
    t.string "stp_payment_type"
    t.string "codi_transaction_number"
    t.datetime "entry_date", precision: nil
    t.index ["external_id"], name: "index_purchase_order_payments_on_external_id"
    t.index ["internal_dispersion_id"], name: "index_purchase_order_payments_on_internal_dispersion_id"
    t.index ["payable_type", "payable_id"], name: "index_purchase_order_payments_on_payable_type_and_payable_id"
    t.index ["purchase_order_id"], name: "index_purchase_order_payments_on_purchase_order_id"
  end

  create_table "purchase_orders", id: :serial, force: :cascade do |t|
    t.string "external_id"
    t.string "billable_type"
    t.integer "billable_id"
    t.integer "period_expense_id", null: false
    t.integer "status", default: 1, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "payment_method"
    t.string "payment_source"
    t.index ["billable_type", "billable_id"], name: "index_purchase_orders_on_billable_type_and_billable_id"
    t.index ["created_at"], name: "index_purchase_orders_on_created_at"
    t.index ["external_id"], name: "index_purchase_orders_on_external_id"
    t.index ["period_expense_id"], name: "index_purchase_orders_on_period_expense_id"
  end

  create_table "questions", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "question_type"
    t.integer "survey_id"
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "backup_pdf", default: false
    t.index ["survey_id"], name: "index_questions_on_survey_id"
  end

  create_table "real_estate_agencies", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "reason_to_leave_tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recommendations", id: :serial, force: :cascade do |t|
    t.string "contact_email"
    t.string "admin_email"
    t.string "admin_phone"
    t.string "admin_name"
    t.boolean "contacted", default: false
    t.boolean "verified", default: false
    t.boolean "closed", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "regions", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "region_number"
    t.integer "region_order"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "reports", force: :cascade do |t|
    t.string "category"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "recipients_option"
    t.integer "user_id"
    t.integer "community_id"
    t.string "data"
    t.boolean "sent", default: false
    t.string "no_emails_document_url"
    t.string "document_url"
    t.string "type"
    t.index ["community_id"], name: "index_reports_on_community_id"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "reports_property_users", force: :cascade do |t|
    t.integer "report_id"
    t.integer "property_user_id"
    t.string "email"
    t.index ["property_user_id"], name: "index_reports_property_users_on_property_user_id"
    t.index ["report_id"], name: "index_reports_property_users_on_report_id"
  end

  create_table "salaries", id: :serial, force: :cascade do |t|
    t.integer "base_price", default: 0
    t.float "week_hours", default: 45.0
    t.integer "transportation_benefit", default: 0
    t.integer "lunch_benefit", default: 0
    t.integer "number_of_loads", default: 0
    t.string "afp"
    t.string "isapre", default: "Fonasa"
    t.string "contract_type", default: "Indefinido"
    t.string "age", default: "Entre 18 y 65 años"
    t.integer "employee_id"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "employee_type"
    t.float "plan_isapre"
    t.datetime "start_date", precision: nil
    t.float "additional_hour_price", default: 50.0
    t.string "place_of_payment"
    t.integer "tipo_empleado", default: 0
    t.string "payment_type", default: "Transferencia"
    t.string "bank", default: ""
    t.string "account_number", default: ""
    t.string "account_type", default: "Cuenta Corriente"
    t.string "account_rut", default: "Cuenta Corriente"
    t.text "comments"
    t.integer "mothernal_number_of_loads", default: 0
    t.integer "invalid_number_of_loads", default: 0
    t.boolean "subsidio_trabajador_joven", default: false
    t.string "asignacion_familiar_tramo", default: "D"
    t.text "payment_message"
    t.float "additional_hour_price_2", default: 0.0
    t.float "additional_hour_price_3", default: 0.0
    t.boolean "has_afp", default: true
    t.boolean "has_seguro_cesantia", default: true
    t.integer "afp_second_account", default: 0
    t.float "tasa_pactada_sustitutiva", default: 0.0
    t.string "puesto_trabajo_pesado"
    t.float "porcentaje_cotizacion_puesto_trabajo_pesado", default: 0.0
    t.string "institucion_apvi"
    t.bigint "numero_contrato_apvi", default: 0
    t.boolean "pago_directo_apvi", default: true
    t.string "institucion_apvc"
    t.bigint "numero_contrato_apvc", default: 0
    t.boolean "pago_directo_apvc", default: true
    t.string "spouse_afp"
    t.string "ex_caja_regimen"
    t.float "tasa_cotizacion_ex_caja", default: 0.0
    t.boolean "has_ips", default: false
    t.string "ex_caja_regimen_desahucio"
    t.float "tasa_cotizacion_desahucio_ex_caja", default: 0.0
    t.bigint "numero_fun", default: 0
    t.boolean "plan_isapre_en_uf", default: true
    t.integer "descuento_dental_ccaf", default: 0
    t.integer "descuento_leasing_ccaf", default: 0
    t.integer "descuento_seguro_de_vida_ccaf", default: 0
    t.integer "otros_descuentos_ccaf", default: 0
    t.integer "cotizacion_ccaf_no_isapre", default: 0
    t.integer "descuento_cargas_familiares_ccaf", default: 0
    t.string "rut_pagadora_subsidio"
    t.string "otros_datos_empresa"
    t.boolean "has_isapre", default: true
    t.integer "days_per_week", default: 5
    t.boolean "daily_wage", default: false
    t.datetime "contract_file_updated_at", precision: nil
    t.string "institucion_apvi2"
    t.bigint "numero_contrato_apvi2", default: 0
    t.boolean "pago_directo_apvi2", default: true
    t.string "ccaf2", default: "Sin CCAF"
    t.integer "ccaf2_amount", default: 0
    t.boolean "bono_diario_colacion_movilizacion", default: false
    t.date "afc_start_date"
    t.datetime "vacations_start_date", precision: nil
    t.string "isapre_codelco"
    t.boolean "subsidy_young_worker", default: false
    t.integer "person_with_disability", default: 0
    t.integer "prior_quotations", default: 0
    t.string "contract_file"
    t.index ["employee_id"], name: "index_salaries_on_employee_id"
  end

  create_table "salary_additional_info_drafts", force: :cascade do |t|
    t.bigint "salary_payment_draft_id", null: false
    t.text "class"
    t.integer "type"
    t.text "name"
    t.integer "value", default: 0
    t.boolean "post_tax", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["salary_payment_draft_id"], name: "index_salary_additional_info_drafts_on_salary_payment_draft_id"
  end

  create_table "salary_additional_infos", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "value"
    t.boolean "discount", default: false
    t.integer "salary_payment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "checked", default: false
    t.boolean "post_tax", default: false
    t.index ["salary_payment_id"], name: "index_salary_additional_infos_on_salary_payment_id"
  end

  create_table "salary_payment_drafts", force: :cascade do |t|
    t.bigint "salary_id", null: false
    t.bigint "payment_period_expense_id", null: false
    t.bigint "creator_id"
    t.bigint "updater_id"
    t.integer "extra_hour", default: 0
    t.integer "extra_hour_2", default: 0
    t.integer "extra_hour_3", default: 0
    t.integer "worked_days", default: 0
    t.integer "bono_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_salary_payment_drafts_on_creator_id"
    t.index ["payment_period_expense_id"], name: "index_salary_payment_drafts_on_payment_period_expense_id"
    t.index ["salary_id"], name: "index_salary_payment_drafts_on_salary_id"
    t.index ["updater_id"], name: "index_salary_payment_drafts_on_updater_id"
  end

  create_table "salary_payments", id: :serial, force: :cascade do |t|
    t.float "extra_hour", default: 0.0
    t.integer "discount_days", default: 0
    t.integer "advance", default: 0
    t.integer "advance_gratifications", default: 0
    t.integer "apv", default: 0
    t.integer "special_bonus", default: 0
    t.integer "refund", default: 0
    t.integer "viaticum", default: 0
    t.integer "lost_cash_allocation", default: 0
    t.integer "allocation_tool_wear", default: 0
    t.integer "union_fee", default: 0
    t.integer "legal_holds", default: 0
    t.integer "period_expense_id"
    t.integer "salary_id"
    t.integer "total_liquido", default: 0
    t.text "library_response"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "total_discount", default: 0
    t.integer "total_haberes", default: 0
    t.boolean "nullified", default: false
    t.datetime "nullified_at", precision: nil
    t.text "pdf_value"
    t.integer "aliquot_id", default: 0
    t.float "mutual", default: 0.0
    t.integer "ccaf", default: 0
    t.integer "total_liquido_a_pagar", default: 0
    t.integer "total_imponible", default: 0
    t.integer "total_discount_2", default: 0
    t.integer "haberes_no_imp_comunidad", default: 0
    t.integer "commision", default: 0
    t.integer "bonus", default: 0
    t.datetime "document_updated_at", precision: nil
    t.integer "tipo_apv", default: 1
    t.integer "otros_costos_empresa", default: 0
    t.integer "asignacion_familiar", default: 0
    t.integer "deposito_convenido", default: 0
    t.string "caja_de_compensacion"
    t.float "discount_hours", default: 0.0
    t.integer "bono_responsabilidad", default: 0
    t.string "asignacion_familiar_tramo", default: "Sin Información"
    t.integer "asignacion_familiar_reintegro", default: 0
    t.integer "payment_special_bonus", default: 0
    t.integer "payment_extra_hours", default: 0
    t.integer "mothernal_number_of_loads", default: 0
    t.integer "invalid_number_of_loads", default: 0
    t.integer "number_of_loads", default: 0
    t.boolean "subsidio_trabajador_joven", default: false
    t.integer "dias_licencia", default: 0
    t.integer "descuento_licencia", default: 0
    t.integer "descuentos_imponibles", default: 0
    t.integer "anual_gratifications", default: 0
    t.integer "payment_period_expense_id"
    t.integer "otros_bonos_imponible", default: 0
    t.integer "bono_days"
    t.float "extra_hour_2", default: 0.0
    t.float "extra_hour_3", default: 0.0
    t.integer "service_billing_id"
    t.datetime "pdf_updated_at", precision: nil
    t.integer "payment_extra_hours_2", default: 0
    t.integer "payment_extra_hours_3", default: 0
    t.integer "result_bonus", default: 0
    t.integer "anual_gratification", default: 0
    t.integer "result_disc_missed_days", default: 0
    t.integer "result_disc_missed_hours", default: 0
    t.integer "cotizacion_obligatoria_isapre", default: 0
    t.integer "cotizacion_afp_dependent", default: 0
    t.integer "sis", default: 0
    t.integer "seguro_cesantia_trabajador", default: 0
    t.integer "result_apv", default: 0
    t.integer "result_adicional_salud", default: 0
    t.integer "IUSC", default: 0
    t.integer "empresa_sis", default: 0
    t.integer "seguro_cesantia_empleador", default: 0
    t.integer "renta_imponible_sustitutiva", default: 0
    t.float "aporte_sustitutivo", default: 0.0
    t.integer "cotizacion_puesto_trabajo_pesado", default: 0
    t.integer "cotizacion_trabajador_apvc", default: 0
    t.integer "cotizacion_empleador_apvc", default: 0
    t.integer "spouse_capitalizacion_voluntaria", default: 0
    t.integer "spouse_voluntary_amount", default: 0
    t.integer "spouse_periods_number", default: 0
    t.integer "imponible_ips", default: 0
    t.integer "cotizacion_obligatoria_ips", default: 0
    t.integer "total_imponible_desahucio", default: 0
    t.integer "cotizacion_desahucio", default: 0
    t.integer "worked_days", default: 0
    t.integer "imponible_cesantia", default: 0
    t.integer "imponible_afp", default: 0
    t.float "result_worked_days", default: 0.0
    t.boolean "spouse", default: false
    t.integer "carga_familiar_retroactiva", default: 0
    t.integer "isl", default: 0
    t.boolean "validated", default: false
    t.integer "ultimo_total_imponible_sin_licencia", default: 0
    t.integer "nullified_by"
    t.integer "base_salary", default: 0
    t.integer "lunch_benefit", default: 0
    t.integer "transportation_benefit", default: 0
    t.integer "imponible_mutual", default: 0
    t.boolean "adjust_by_rounding", default: false
    t.float "original_salary_amount_to_pay", default: 0.0
    t.integer "imponible_isapre"
    t.integer "imponible_ccaf"
    t.float "result_missed_days", default: 0.0
    t.boolean "employee_protection_law", default: false
    t.integer "reduction_percentage", default: 0
    t.integer "suspension_or_reduction_days", default: 0
    t.integer "protection_law_code"
    t.float "cotizacion_afp_dependent_employee_suspension"
    t.float "seguro_cesantia_trabajador_employee_suspension"
    t.float "result_adicional_salud_employee_suspension"
    t.float "empresa_sis_employee_suspension"
    t.float "seguro_cesantia_empleador_employee_suspension"
    t.float "employee_suspension_input_amount"
    t.float "afc_informed_rent"
    t.integer "aguinaldo", default: 0
    t.integer "union_pay", default: 0
    t.integer "nursery", default: 0
    t.float "health_quote_pending", default: 0.0
    t.string "document"
    t.string "pdf"
    t.integer "home_office", default: 0
    t.string "creator_type"
    t.bigint "creator_id"
    t.string "updater_type"
    t.bigint "updater_id"
    t.string "nullifier_type"
    t.bigint "nullifier_id"
    t.index ["creator_type", "creator_id"], name: "index_salary_payments_on_creator"
    t.index ["nullifier_type", "nullifier_id"], name: "index_salary_payments_on_nullifier"
    t.index ["period_expense_id"], name: "index_salary_payments_on_period_expense_id"
    t.index ["salary_id"], name: "index_salary_payments_on_salary_id"
    t.index ["service_billing_id"], name: "index_salary_payments_on_service_billing_id"
    t.index ["updater_type", "updater_id"], name: "index_salary_payments_on_updater"
  end

  create_table "server_user_groups", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "locked"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "server_id"
    t.index ["server_id"], name: "index_server_user_groups_on_server_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "service_billing_fees", id: :serial, force: :cascade do |t|
    t.float "price"
    t.integer "period_expense_id"
    t.integer "service_billing_id"
    t.integer "number"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["period_expense_id"], name: "index_service_billing_fees_on_period_expense_id"
    t.index ["service_billing_id"], name: "index_service_billing_fees_on_service_billing_id"
  end

  create_table "service_billing_meters", id: :serial, force: :cascade do |t|
    t.integer "service_billing_id"
    t.integer "meter_id"
    t.float "value", default: 100.0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "proratable_type"
    t.integer "proratable_id"
    t.index ["meter_id"], name: "index_service_billing_meters_on_meter_id"
    t.index ["proratable_type", "proratable_id"], name: "index_sbm_on_proratable_type_and_proratable_id"
    t.index ["service_billing_id"], name: "index_service_billing_meters_on_service_billing_id"
  end

  create_table "service_billings", id: :serial, force: :cascade do |t|
    t.decimal "price", precision: 19, scale: 4
    t.string "name"
    t.integer "amount"
    t.boolean "paid", default: false
    t.integer "category_id"
    t.integer "supplier_id"
    t.integer "community_id"
    t.integer "period_expense_id"
    t.boolean "distributed", default: false
    t.string "payment_number"
    t.integer "payment_type", default: 0
    t.datetime "paid_at", precision: nil
    t.text "notes"
    t.datetime "bill_updated_at", precision: nil
    t.datetime "receipt_updated_at", precision: nil
    t.string "document_number"
    t.integer "document_type", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "reserve_fund", default: false
    t.integer "folio"
    t.integer "aliquot_id"
    t.integer "excel_upload_id"
    t.integer "previous_supplier_id"
    t.integer "fund_id", default: -1
    t.boolean "active", default: true
    t.datetime "nullified_at", precision: nil
    t.integer "nullified_by", default: -1
    t.boolean "has_fees", default: false
    t.integer "number_of_fees", default: 0
    t.boolean "has_checks", default: false
    t.float "previous_feeable_price", default: 0.0
    t.boolean "include_in_bank_conciliation", default: true
    t.string "receipt"
    t.string "bill"
    t.bigint "created_by"
    t.boolean "recurrent", default: false
    t.string "importer_type"
    t.integer "importer_id"
    t.string "creator_type"
    t.bigint "creator_id"
    t.string "updater_type"
    t.bigint "updater_id"
    t.date "invoice_date"
    t.index ["category_id"], name: "index_service_billings_on_category_id"
    t.index ["community_id"], name: "index_service_billings_on_community_id"
    t.index ["created_by"], name: "index_service_billings_on_created_by"
    t.index ["creator_type", "creator_id"], name: "index_service_billings_on_creator"
    t.index ["importer_type", "importer_id"], name: "index_service_billings_on_importer_type_and_importer_id"
    t.index ["period_expense_id"], name: "index_service_billings_on_period_expense_id"
    t.index ["supplier_id"], name: "index_service_billings_on_supplier_id"
    t.index ["updater_type", "updater_id"], name: "index_service_billings_on_updater"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.integer "value", default: 0
    t.string "code"
    t.integer "community_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["community_id"], name: "index_settings_on_community_id"
  end

  create_table "sii_scrapers", force: :cascade do |t|
    t.date "date"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "slots", id: :serial, force: :cascade do |t|
    t.integer "common_space_id"
    t.time "start_time"
    t.time "end_time"
    t.integer "weekday"
    t.integer "order", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["common_space_id"], name: "index_slots_on_common_space_id"
  end

  create_table "smart_links", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "community_id"
    t.boolean "property_user"
    t.integer "amount_of_usages", default: 0
    t.string "link"
    t.string "token"
    t.string "redirect_path"
    t.string "subject_type"
    t.json "extra_data"
    t.datetime "expiration_date", precision: nil
    t.datetime "last_use", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_smart_links_on_community_id"
    t.index ["token"], name: "index_smart_links_on_token"
    t.index ["user_id"], name: "index_smart_links_on_user_id"
  end

  create_table "social_credit_fees", id: :serial, force: :cascade do |t|
    t.integer "social_credit_id"
    t.integer "period_expense_id"
    t.integer "price"
    t.integer "salary_payment_id"
    t.boolean "supplier_paid", default: false
    t.boolean "employeed_paid", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "social_credits", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "supplier"
    t.integer "start_period_expense_id"
    t.integer "employee_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
  end

  create_table "step_closings", force: :cascade do |t|
    t.bigint "closing_log_id"
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.string "step_name"
    t.string "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closing_log_id"], name: "index_step_closings_on_closing_log_id"
  end

  create_table "subproperties", id: :serial, force: :cascade do |t|
    t.string "name"
    t.float "size", default: 0.0
    t.integer "property_id"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "excel_upload_id"
    t.boolean "old", default: false
    t.float "tower_size", default: 0.0
    t.string "importer_type"
    t.integer "importer_id"
    t.index ["importer_type", "importer_id"], name: "index_subproperties_on_importer_type_and_importer_id"
    t.index ["property_id"], name: "index_subproperties_on_property_id"
  end

  create_table "superadmin_permissions", force: :cascade do |t|
    t.string "code", null: false
    t.boolean "permanent", default: false
    t.datetime "expirates_at", precision: nil
    t.boolean "active", default: true
    t.integer "tier", default: 1
    t.string "entity_type", null: false
    t.integer "entity_id", null: false
    t.string "object_type"
    t.integer "object_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_type", "entity_id"], name: "index_superadmin_permissions_on_entity_type_and_entity_id"
    t.index ["object_type", "object_id"], name: "index_superadmin_permissions_on_object_type_and_object_id"
  end

  create_table "suppliers", id: :serial, force: :cascade do |t|
    t.integer "balance_id"
    t.integer "community_id"
    t.string "name"
    t.boolean "public", default: false
    t.string "rut"
    t.string "slug"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "active", default: true
    t.integer "new_supplier_id"
    t.text "comments"
  end

  create_table "supports", force: :cascade do |t|
    t.boolean "freshchat_active", default: true
    t.boolean "monday", default: true
    t.boolean "tuesday", default: true
    t.boolean "wednesday", default: true
    t.boolean "thursday", default: true
    t.boolean "friday", default: true
    t.boolean "saturday", default: true
    t.boolean "sunday", default: true
    t.time "chat_min_time", default: "2000-01-01 09:00:00"
    t.time "chat_max_time", default: "2000-01-01 20:00:00"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "surcharges", force: :cascade do |t|
    t.boolean "active", default: true
    t.bigint "creator_id"
    t.text "description"
    t.datetime "fined_at", precision: nil
    t.bigint "fund_id"
    t.bigint "origin_debt_id"
    t.boolean "paid", default: false
    t.bigint "property_id"
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "price", precision: 19, scale: 2, default: "0.0"
    t.index ["creator_id"], name: "index_surcharges_on_creator_id"
    t.index ["fund_id"], name: "index_surcharges_on_fund_id"
    t.index ["origin_debt_id"], name: "index_surcharges_on_origin_debt_id"
    t.index ["property_id"], name: "index_surcharges_on_property_id"
  end

  create_table "surveys", id: :serial, force: :cascade do |t|
    t.string "name", default: ""
    t.text "description", default: ""
    t.date "end_at"
    t.boolean "physical_backup", default: false
    t.datetime "published_at", precision: nil
    t.boolean "published", default: false
    t.integer "community_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "results_published", default: false
    t.boolean "closed", default: false
    t.boolean "active", default: true
    t.integer "post_id"
    t.boolean "legacy", default: false
    t.integer "answer_counting_method", default: 0
    t.integer "eligible_voters_size"
    t.index ["answer_counting_method"], name: "index_surveys_on_answer_counting_method"
    t.index ["community_id"], name: "index_surveys_on_community_id"
  end

  create_table "tasks", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "guide_id"
    t.integer "next_task_id"
    t.string "associated_class"
    t.index ["guide_id"], name: "index_tasks_on_guide_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tokens", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "value"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "tours", force: :cascade do |t|
    t.integer "user_id"
    t.string "resource_model"
    t.boolean "visible"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tours_on_user_id"
  end

  create_table "towers", id: :serial, force: :cascade do |t|
    t.integer "community_id"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.float "total_area", default: 0.0
    t.string "bill_header_1", default: "Prorrateo "
  end

  create_table "transfers", id: :serial, force: :cascade do |t|
    t.integer "period_expense_id", null: false
    t.integer "transfer_type", default: 0
    t.date "transfer_date"
    t.float "transfer_percentage", null: false
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "excel_upload_id"
    t.index ["period_expense_id"], name: "index_transfers_on_period_expense_id"
  end

  create_table "unbalanced_properties", force: :cascade do |t|
    t.bigint "unbalanced_properties_report_id", null: false
    t.bigint "property_id", null: false
    t.integer "unbalance_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_unbalanced_properties_on_property_id"
    t.index ["unbalanced_properties_report_id"], name: "index_unbalanced_properties_on_unbalanced_properties_report_id"
  end

  create_table "unbalanced_properties_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "usage_interactions", force: :cascade do |t|
    t.decimal "ggcc_notified", default: "0.0"
    t.decimal "pending_debts_setting_enabled", default: "0.0"
    t.decimal "payments_created", default: "0.0"
    t.decimal "payments_notified", default: "0.0"
    t.decimal "service_billings", default: "0.0"
    t.decimal "posts_created", default: "0.0"
    t.decimal "reports_or_balance_use", default: "0.0"
    t.decimal "issues_created", default: "0.0"
    t.decimal "packages_created", default: "0.0"
    t.decimal "logbooks_created", default: "0.0"
    t.decimal "guest_registries_created", default: "0.0"
    t.decimal "events_created", default: "0.0"
    t.decimal "surveys_created", default: "0.0"
    t.decimal "maintenances_created", default: "0.0"
    t.decimal "salary_payments_created", default: "0.0"
    t.decimal "online_payments", default: "0.0"
    t.decimal "properties_with_email", default: "0.0"
    t.decimal "active_properties", default: "0.0"
    t.decimal "ggcc_issued", default: "0.0"
    t.decimal "property_fines_created", default: "0.0"
    t.decimal "match_feliz_payments", default: "0.0"
    t.decimal "spei_payments", default: "0.0"
    t.decimal "payment_billed", default: "0.0"
    t.decimal "current_score", default: "0.0"
    t.date "period"
    t.bigint "community_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_usage_interactions_on_community_id"
  end

  create_table "user_activity_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "community_id", null: false
    t.bigint "property_id", null: false
    t.datetime "last_activity_time", precision: nil, null: false
    t.integer "activity_origin", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_user_activity_logs_on_community_id"
    t.index ["property_id"], name: "index_user_activity_logs_on_property_id"
    t.index ["user_id"], name: "index_user_activity_logs_on_user_id"
  end

  create_table "user_demos", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "number"
    t.string "rol"
    t.integer "request_counter", default: 0
    t.boolean "must_contact", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "requested_instalation", default: false
    t.datetime "requested_instalation_at", precision: nil
    t.boolean "before_request_instalation", default: false
    t.boolean "contacted", default: false
    t.integer "plan", default: 0
    t.integer "page_visit", default: 0
    t.datetime "last_visit_at", precision: nil
    t.string "contact_reason"
    t.string "keyword"
    t.string "origin"
    t.string "url"
    t.string "company"
    t.boolean "blocked"
    t.string "vendor"
    t.boolean "accepted_tour", default: false
    t.boolean "finished_tour", default: false
    t.integer "next_count", default: 0
    t.integer "back_count", default: 0
    t.datetime "finished_tour_at", precision: nil
    t.string "country_code"
    t.string "crm_id"
    t.boolean "crm_synced", default: false
    t.index ["crm_synced"], name: "index_user_demos_on_crm_synced"
  end

  create_table "user_guides", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "guide_id"
    t.integer "active_task_id"
    t.integer "community_id"
    t.boolean "completed", default: false
    t.boolean "ongoing", default: true
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "user_oauths", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "provider"
    t.string "uid"
    t.string "oauth_token"
    t.datetime "oauth_expires_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "user_read_posts", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "post_id"
    t.boolean "read", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["post_id"], name: "index_user_read_posts_on_post_id"
    t.index ["user_id", "post_id"], name: "index_user_read_posts_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_user_read_posts_on_user_id"
  end

  create_table "user_read_surveys", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "survey_id"
    t.boolean "read", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["survey_id"], name: "index_user_read_surveys_on_survey_id"
    t.index ["user_id", "survey_id"], name: "index_user_read_surveys_on_user_id_and_survey_id", unique: true
    t.index ["user_id"], name: "index_user_read_surveys_on_user_id"
  end

  create_table "user_teams", force: :cascade do |t|
    t.integer "team_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_user_teams_on_team_id"
    t.index ["user_id"], name: "index_user_teams_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "slug"
    t.string "email"
    t.string "image"
    t.string "password_salt"
    t.string "password_hash"
    t.boolean "active", default: true
    t.boolean "admin", default: false
    t.boolean "first_login", default: true
    t.boolean "deleted", default: false
    t.integer "sign_in_count", default: 0
    t.datetime "last_sign_in_at", precision: nil
    t.string "phone"
    t.boolean "demo", default: false
    t.date "demo_start"
    t.date "available_until"
    t.string "crm_email", default: "comunidadfeliz@pipedrivemail.com"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "avatar_updated_at", precision: nil
    t.integer "try_login", default: 0
    t.integer "excel_upload_id"
    t.string "rut"
    t.string "mother_last_name"
    t.boolean "accepted_terms_and_conditions", default: false
    t.boolean "need_to_accept_conditions", default: false
    t.integer "real_estate_agency_id"
    t.boolean "validated", default: false
    t.integer "customer_number"
    t.boolean "unknown_user", default: false
    t.string "country_code", default: "CL"
    t.integer "mobile_sign_in_count", default: 0
    t.datetime "last_mobile_sign_in_at", precision: nil
    t.boolean "paid_online_by_app", default: false
    t.datetime "last_online_payment_by_app", precision: nil
    t.boolean "created_by_oauth", default: false
    t.boolean "new_interface", default: false
    t.date "last_notification_date", default: "2022-10-10"
    t.integer "number_notifications", default: 0
    t.string "validate_email"
    t.string "fcm_registration_token"
    t.integer "server_user_group_id"
    t.boolean "admin_tour_seen", default: false
    t.string "avatar"
    t.string "identity_document_back"
    t.string "identity_document_front"
    t.datetime "identity_document_back_updated_at", precision: nil
    t.datetime "identity_document_front_updated_at", precision: nil
    t.boolean "opt_in_email_campaign", default: true, null: false
    t.jsonb "metadata", default: {}
    t.datetime "payments_terms_conditions_date", precision: nil
    t.string "importer_type"
    t.integer "importer_id"
    t.string "mfa_secret"
    t.boolean "mfa_active", default: false
    t.boolean "mfa_enabled", default: false
    t.date "mfa_last_updated_at"
    t.index ["customer_number"], name: "index_users_on_customer_number", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["importer_type", "importer_id"], name: "index_users_on_importer_type_and_importer_id"
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "vacations", id: :serial, force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.integer "days"
    t.datetime "voucher_updated_at", precision: nil
    t.datetime "documentation_updated_at", precision: nil
    t.string "name"
    t.integer "employee_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.datetime "deactivated_at", precision: nil
    t.string "voucher_text_period"
    t.string "documentation"
    t.string "voucher"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at", precision: nil
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "visitor_settings", force: :cascade do |t|
    t.integer "flexibility_in_minutes", default: 240, null: false
    t.boolean "strict_community", null: false
    t.bigint "community_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["community_id"], name: "index_visitor_settings_on_community_id"
  end

  create_table "webpay_init_transactions", id: :serial, force: :cascade do |t|
    t.integer "property_id"
    t.string "returnURL"
    t.string "finalURL"
    t.string "commerceCode"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.string "token"
    t.string "billable_type"
    t.integer "billable_id"
    t.integer "amount"
    t.index ["billable_type", "billable_id"], name: "index_webpay_init_transactions_on_billable_type_and_billable_id"
    t.index ["property_id"], name: "index_webpay_init_transactions_on_property_id"
  end

  create_table "webpay_invoice_results", id: :serial, force: :cascade do |t|
    t.string "accountingDate"
    t.string "transactionDate"
    t.string "vci"
    t.string "urlRedirection"
    t.string "cardnumber"
    t.string "authorizationCode"
    t.string "paymentTypeCode"
    t.string "responseCode"
    t.string "amount"
    t.string "sharesNumber"
    t.string "commerceCode"
    t.integer "invoice_payment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "token"
    t.integer "buy_order_id"
    t.index ["buy_order_id"], name: "index_webpay_invoice_results_on_buy_order_id"
    t.index ["invoice_payment_id"], name: "index_webpay_invoice_results_on_invoice_payment_id"
  end

  create_table "webpay_settings", id: :serial, force: :cascade do |t|
    t.integer "community_id", null: false
    t.string "commerce_code"
    t.float "credit_commission", default: 0.01547, null: false
    t.float "debit_commission", default: 0.01547, null: false
    t.float "phi", default: 0.0, null: false
    t.float "delta", default: 0.0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "commerce_code_oneclick"
    t.float "credit_commission_oneclick", default: 0.01547
    t.float "debit_commission_oneclick", default: 0.01547
    t.float "phi_oneclick", default: 0.0
    t.float "delta_oneclick", default: 0.0
    t.index ["community_id"], name: "index_webpay_settings_on_community_id"
  end

  create_table "webpay_transaction_results", id: :serial, force: :cascade do |t|
    t.string "accountingDate"
    t.string "transactionDate"
    t.string "vci"
    t.string "urlRedirection"
    t.string "cardnumber"
    t.string "authorizationCode"
    t.string "paymentTypeCode"
    t.string "responseCode"
    t.string "sharesNumber"
    t.string "commerceCode"
    t.integer "property_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "folio", default: 0
    t.string "token"
    t.boolean "nullify", default: true
    t.string "billable_type"
    t.integer "billable_id"
    t.integer "amount"
    t.integer "buy_order_id"
    t.index ["billable_type", "billable_id"], name: "index_wtr_on_billable_type_and_billable_id"
    t.index ["buy_order_id"], name: "index_webpay_transaction_results_on_buy_order_id"
    t.index ["property_id"], name: "index_webpay_transaction_results_on_property_id"
  end

  add_foreign_key "advertisement_users", "advertisements"
  add_foreign_key "advertisement_users", "users"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "bank_accounts", "communities"
  add_foreign_key "banking_settings", "communities"
  add_foreign_key "collaborators", "communities"
  add_foreign_key "community_packages", "accounts"
  add_foreign_key "community_transactions", "bank_accounts"
  add_foreign_key "companion_guests", "guest_registries"
  add_foreign_key "customer_success_settings", "communities"
  add_foreign_key "debit_recurrences", "aliquots"
  add_foreign_key "debit_recurrences", "communities"
  add_foreign_key "debit_recurrences", "funds"
  add_foreign_key "debit_recurrences", "users", column: "creator_id"
  add_foreign_key "dispersed_payments", "communities"
  add_foreign_key "dispersed_payments", "payments"
  add_foreign_key "finiquito_discounts", "finiquitos"
  add_foreign_key "finkok_response_payments", "finkok_responses"
  add_foreign_key "finkok_response_payments", "payments"
  add_foreign_key "finkok_responses", "finkok_responses", column: "parent_id"
  add_foreign_key "finkok_responses", "invoice_payment_assignments"
  add_foreign_key "free_debt_certificate_settings", "communities"
  add_foreign_key "guest_entries", "guest_registries"
  add_foreign_key "guest_registries", "communities"
  add_foreign_key "guest_registries", "excel_uploads"
  add_foreign_key "guest_registries", "properties"
  add_foreign_key "guest_registries", "users", column: "nullifier_id"
  add_foreign_key "inactive_communities", "communities"
  add_foreign_key "internal_banking_settings", "communities"
  add_foreign_key "internal_dispersions", "communities"
  add_foreign_key "internal_dispersions", "dispersed_payments"
  add_foreign_key "internal_dispersions", "payments"
  add_foreign_key "issues", "communities"
  add_foreign_key "issues", "properties"
  add_foreign_key "issues", "users", column: "closed_by_id"
  add_foreign_key "issues", "users", column: "deleted_by_id"
  add_foreign_key "issues", "users", column: "user_in_charge_id"
  add_foreign_key "library_files", "communities", on_update: :cascade, on_delete: :cascade
  add_foreign_key "license_drafts", "salary_payment_drafts"
  add_foreign_key "logbooks", "users"
  add_foreign_key "logbooks", "users", column: "nullifier_id"
  add_foreign_key "meter_periods", "meters"
  add_foreign_key "meter_periods", "period_expenses"
  add_foreign_key "notification_user_logs", "notification_logs"
  add_foreign_key "notification_user_logs", "users"
  add_foreign_key "package_notifications", "properties"
  add_foreign_key "payment_portal_settings", "communities"
  add_foreign_key "payments", "deductions"
  add_foreign_key "periodic_online_payment_executions", "periodic_online_payments"
  add_foreign_key "periodic_online_payment_executions", "purchase_order_payments"
  add_foreign_key "points", "communities"
  add_foreign_key "points", "users"
  add_foreign_key "post_templates", "communities"
  add_foreign_key "profiles", "communities"
  add_foreign_key "profiles", "users"
  add_foreign_key "property_fine_group_discounts", "property_fine_groups"
  add_foreign_key "property_fine_group_surcharges", "property_fine_groups"
  add_foreign_key "property_fine_groups", "aliquots"
  add_foreign_key "property_fine_groups", "communities"
  add_foreign_key "property_fine_groups", "debit_recurrences"
  add_foreign_key "property_fine_groups", "funds"
  add_foreign_key "property_fines", "property_fine_groups"
  add_foreign_key "property_user_validations", "property_users"
  add_foreign_key "purchase_order_payments", "dispersed_payments", column: "dispertion_id", name: "purchase_order_payment_dispertion_id_fk"
  add_foreign_key "purchase_order_payments", "internal_dispersions"
  add_foreign_key "purchase_order_payments", "purchase_orders"
  add_foreign_key "questions", "surveys"
  add_foreign_key "reports", "communities"
  add_foreign_key "reports", "users", on_update: :cascade, on_delete: :restrict
  add_foreign_key "reports_property_users", "property_users"
  add_foreign_key "reports_property_users", "reports"
  add_foreign_key "salary_additional_info_drafts", "salary_payment_drafts"
  add_foreign_key "salary_payment_drafts", "period_expenses", column: "payment_period_expense_id"
  add_foreign_key "salary_payment_drafts", "salaries"
  add_foreign_key "smart_links", "communities"
  add_foreign_key "smart_links", "users"
  add_foreign_key "step_closings", "closing_logs"
  add_foreign_key "tasks", "guides"
  add_foreign_key "unbalanced_properties", "properties"
  add_foreign_key "unbalanced_properties", "unbalanced_properties_reports"
  add_foreign_key "user_activity_logs", "communities"
  add_foreign_key "user_activity_logs", "properties"
  add_foreign_key "user_activity_logs", "users"
  add_foreign_key "user_read_posts", "posts"
  add_foreign_key "user_read_posts", "users"
  add_foreign_key "user_read_surveys", "surveys"
  add_foreign_key "user_read_surveys", "users"
  add_foreign_key "user_teams", "teams"
  add_foreign_key "user_teams", "users"
  add_foreign_key "visitor_settings", "communities"
  add_foreign_key "webpay_init_transactions", "properties"
  add_foreign_key "webpay_invoice_results", "invoice_payments"
  add_foreign_key "webpay_transaction_results", "properties"
end
