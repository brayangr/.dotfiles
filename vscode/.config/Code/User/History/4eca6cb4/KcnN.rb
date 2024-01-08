require 'nokogiri'
require 'fastimage'

class StandardPdfServiceObject < StandardServiceObject
  include ActionView::Helpers::SanitizeHelper
  include ApplicationHelper
  include Constants::Prawn::Colors
  include Constants::Prawn::LineWidths
  include Constants::Prawn::LetterSizes
  include PrawnHelper

  DEFAULT_SETTINGS = {
    margin: [110, 20, 35, 20]
  }

  def post_initialize
    @community = params[:community] || Community.find_by(id: params[:community_id])
    initialize_pdf
    charge_fonts
  end

  def initialize_pdf(settings: DEFAULT_SETTINGS)
    page_size = Setting.paper_size_hash(@community.get_setting_value('paper_size'), processor: :prawn_pdf)[:page_size].upcase
    settings.merge!({ page_size: page_size })
    @pdf = Prawn::Document.new(**settings)
  end

  def charge_fonts(font_size: 12)
    @pdf.font_families.update(
      'Montserrat' => {
        bold:        Rails.root.join('app/assets/fonts/Montserrat/Montserrat-Bold.ttf'),
        italic:      Rails.root.join('app/assets/fonts/Montserrat/Montserrat-Italic.ttf'),
        bold_italic: Rails.root.join('app/assets/fonts/Montserrat/Montserrat-BoldItalic.ttf'),
        normal:      Rails.root.join('app/assets/fonts/Montserrat/Montserrat-Medium.ttf'),
        light:       Rails.root.join('app/assets/fonts/Montserrat/Montserrat-Light.ttf'),
        semibold:    Rails.root.join('app/assets/fonts/Montserrat/Montserrat-SemiBold.ttf')
      }
    )
    @pdf.font('Montserrat', style: :normal, size: font_size, color: '333333')
  end

  def add_header(add_date: false, repeat: true)
    @pdf.repeat(repeat ? :all : [1]) do
      @pdf.canvas do
        @pdf.bounding_box([@pdf.bounds.left + 20, @pdf.bounds.top - 30], width: @pdf.bounds.width - 40, height: 70) do
          if community_has_logo
            logo_width = logo_factor * community_logo_dimensions.first
            start_position = logo_width + 5
            new_width = @pdf.bounds.width * 0.7 - logo_width
            @pdf.bounding_box([@pdf.bounds.left, @pdf.bounds.top], width: logo_width, height: 60) do
              @pdf.image community_logo, fit: [logo_width, 60], position: :left
            end
          else
            start_position = @pdf.bounds.left
            new_width = @pdf.bounds.width * 0.7
          end
          @pdf.bounding_box([start_position, @pdf.bounds.top], width: new_width) do
            @pdf.text @community.name.strip, style: :bold, size: 10
            @pdf.move_down 5
            @pdf.text @community.address, size: 10
            @pdf.move_down 5
            @pdf.text @community.rut&.rutify, size: 10 if @community.rut.present?
          end
          @pdf.bounding_box([@pdf.bounds.width * 0.7, @pdf.bounds.top], width: @pdf.bounds.width * 0.3) do
            if add_date
              @pdf.text I18n.l(Date.today, format: :long), size: 9, align: :right
            else
              @pdf.image 'app/assets/images/logotipo-cf.jpg', fit: [140, 70], position: :right
            end

            yield if block_given?
          end
        end
      end
    end
  end

  def add_title(title, upcase: true, margin_bottom: 30)
    formatted_title = upcase ? title.upcase : title
    @pdf.bounding_box([@pdf.bounds.left, @pdf.cursor], width: @pdf.bounds.width, height: 30) do
      @pdf.fill_color '4CBF8C'
      @pdf.stroke_color '00A27F'
      @pdf.fill_and_stroke_rounded_rectangle [@pdf.bounds.left, @pdf.cursor], @pdf.bounds.width, 30, 4
      @pdf.fill_color '333333'
      @pdf.text_box formatted_title.prawn_color('FFFFFF'), width: @pdf.bounds.width, align: :center, inline_format: true, style: :bold, valign: :center, size: 12
    end
    @pdf.stroke_color '333333'
    @pdf.move_down margin_bottom
  end

  def dual_signature_box(person_data: [], community_data: [], vertical_offset: 200)
    Prawn::DualSignatureBox.new(person_data: person_data, community_data: community_data, vertical_offset: vertical_offset, document: @pdf).render
  end

  def dual_signature_box_image(first_signature: [], second_signature: [], signature_height_box: 135, signature_in_bottom: false, signature: nil)
    Prawn::DualSignatureBoxImage.new(
      first_signature: first_signature, second_signature: second_signature,
      signature_height_box: signature_height_box, signature_in_bottom: signature_in_bottom,
      community_signature: signature || community_signature, pdf: @pdf
    ).render
  end

  def community_has_logo
    @community_has_logo ||= @community.has_company_image?
  end

  def community_logo
    @community_logo ||= URI.parse(@community.get_company_image).open
  end

  def community_logo_dimensions
    @community_logo_dimensions ||= FastImage.size(@community.get_company_image)
  end

  def logo_factor
    width, height = community_logo_dimensions
    [100.to_f / width, 60.to_f / height].min
  end

  def community_has_signature
    @community_has_signature ||= @community.has_signature?
  end

  def community_signature
    return nil unless community_has_signature

    @community_signature ||= URI.parse(@community.get_signature).open
  end

  def community_signature_dimensions
    @community_signature_dimensions ||= FastImage.size(@community.get_signature)
  end

  def signature_factor
    width, height = community_signature_dimensions
    [100.to_f / width, 64.to_f / height].min
  end

  def add_page_numbers
    @pdf.number_pages I18n.t('pdfs.pagination.page_label'), { at: @pdf.bounds.bottom, align: :center, size: 8 }
  end

  def calculate_column_widths(width, column_width_percentages)
    column_width_percentages.map { |percentage| width * percentage }
  end
end
