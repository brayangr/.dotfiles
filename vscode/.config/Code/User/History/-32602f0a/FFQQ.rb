# frozen_string_literal: true

class Payment < ApplicationRecord
  include AttachmentTimerUpdater

  belongs_to :period_expense
  belongs_to :property

  has_one    :community, through: :period_expense

  mount_uploader :receipt, DocumentationUploader

  def save_pdf_in_amazon(content, paper_size, new_design = false)
    path = "#{FileHelper.root_path}payment-#{id}#{Time.now.to_i.to_s[6..10]}.pdf"
    # guardar archivo, pdf_from_url
    file = File.new(path, 'wb')
    settings = { paper_size: paper_size }

    footer_content = ActionController::Base.new.render_to_string(
      template: 'payments/new_design/numbered_footer',
      layout: nil
    )

    other_settings = {
      footer: {
        content: footer_content,
        center: 'true'
      },
      margin: {
        top: 4.76,
        bottom: 10,
        left: 5.29,
        right: 5.29
      }
    }

    settings.merge!(other_settings) if new_design
    byebug
    file << WickedPdf.new.pdf_from_string(content, settings)

    # Guardar en modelo
    self.receipt = file
    save

    file.close

    # limpiar
    File.delete(path)
  end
end
