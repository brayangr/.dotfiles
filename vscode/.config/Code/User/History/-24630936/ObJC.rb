module Remuneration
  module Advances
    class PdfGenerator < StandardPdfServiceObject
      include ApplicationHelper

      def post_initialize
        @advance = params[:advance]
        @employee =  @advance.employee
        @community = @advance.community
        @period_expense = @advance.period_expense
      end

      def call
        initialize_pdf
        charge_fonts
        build_pdf
        @response.add_data(:pdf, @pdf.render)
      end

      private

      def build_pdf
        add_header do
          @pdf.move_down 5
          add_emision_date
        end
        add_title(I18n.t('remuneration.advance.voucher_title'), margin_bottom: 12)
        add_body
        add_signatures
      end

      def add_signatures
        first_signature = { signature_image: false, data: [@employee.to_s, @employee.rut.to_s] }
        second_signature = { signature_image: true, data: [@community.contact_name, @community.name, @community.rut] }
        byebug
        dual_signature_box_image(first_signature: first_signature, second_signature: second_signature,
                                 signature: URI.parse(@community.get_remuneration_signature).open)
      end

      def add_body
        @pdf.text build_content, inline_format: true, size: PX16
      end

      def build_content
        paid_date = I18n.l(@advance.paid_at.to_date, format: :long)
        community = @advance.community
        content = (I18n.t 'remuneration.advance.voucher_text').gsub("{{NAME}}", @employee.to_s).gsub("{{NATIONALITY}}", @employee.citizenship.downcase).gsub("{{RUT}}", @employee.rut).gsub("{{PERIOD}}", @period_expense.to_s).gsub("{{PRICE}}", to_currency(amount: @advance.price, community: @community)).gsub("{{DATE}}", paid_date)
        content += "<br><br>#{I18n.t('remuneration.advance.voucher_comment_text').gsub('{{COMMENT}}', @advance.comment)}" if @advance.comment.present?
        content
      end

      def add_emision_date
        @pdf.formatted_text(
          [
            { text: I18n.t('pdfs.emition_date'), styles: [:bold], size: 10 },
            { text: I18n.l(Date.today, format: :default), size: 10 }
          ],
          align: :right
        )
      end
    end
  end
end
