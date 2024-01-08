module Prawn
  class DualSignatureBoxImage
    include Constants::Prawn::Signature
    include Constants::Prawn::Colors

    def initialize(params)
      @pdf = params[:pdf]
      @community_signature = params[:community_signature]
      @first_signature = params[:first_signature]
      @second_signature = params[:second_signature]
      @signature_height_box = params[:signature_height_box]
      @signature_in_bottom = params[:signature_in_bottom]
    end

    def render
      @pdf.stroke_color GREY_LINE
      position = signature_position
      draw_signature_box(signature: @first_signature, position: [@pdf.bounds.left, position], width: @pdf.bounds.width * 0.5)
      draw_signature_box(signature: @second_signature, position: [@pdf.bounds.width * 0.5, position], width: @pdf.bounds.width * 0.5)
    end

    private

    def draw_signature_box(signature:, position:, width:)
      @pdf.bounding_box(position, width: width, height: @signature_height_box) do
        add_signature_image(@pdf.bounds.left, signature[:signature_image])
        draw_signature_line(width)
        add_signature_text(signature[:data])
      end
    end

    def add_signature_image(horizontal_position, signature_image)
      if @community_signature.present? && signature_image
        @pdf.bounding_box([horizontal_position, @pdf.bounds.top], width: @pdf.bounds.width, height: 64) do
          begin
            @pdf.image @community_signature, fit: [100, 64], position: :center, vposition: :bottom
          rescue
            @pdf.move_down SIGNATURE_SPACE
          end
        end
      else
        @pdf.move_down SIGNATURE_SPACE
      end
    end

    def draw_signature_line(width)
      @pdf.stroke_horizontal_line(width * 0.15, width * 0.85)
    end

    def add_signature_text(signature_data)
      signature_data.each do |element|
        @pdf.move_down TEXT_VERTICAL_SPACE
        @pdf.text element, align: :center, size: 10, inline_format: true
      end
    end

    def signature_position
      if @signature_in_bottom
        @pdf.bounds.bottom
      else
        @pdf.start_new_page if @pdf.cursor < @signature_height_box
        @pdf.cursor
      end
    end
  end
end
