require 'roo'

module Importers
  module Subproperties
    class DataExtractor
      def initialize(file, extension)
        @file = file
        @extension = extension
        @data_array = []
        @errors = []
      end

      def call
        extract_data
        [@data_array, @errors]
      end

      private

      def extract_data
        methods_by_extension = {
          'xlsx' => method(:xlsx_extraction),
          'xls'  => method(:xls_extraction)
        }
        methods_by_extension[@extension].call
      end

      def params_translations
        @params_translations ||= {
          'admin' => {
            'community[id]'     => %i[community_id],
            'property[id]'      => %i[property id],
            'property[address]' => %i[property address],
            'property[name]'    => %i[property name],
            'subproperty[id]'   => %i[subproperty id],
            'subproperty[name]' => %i[subproperty name],
            'subproperty[size]' => %i[subproperty size]
          },
          'user' => {
            'comunidad'           => %i[community_id],
            'propiedad'           => %i[property address],
            'unidad'              => %i[property address],
            'nombre subpropiedad' => %i[subproperty name],
            'tamaño subpropiedad' => %i[subproperty size]
          }
        }
      end

      def translate_dynamic_aliquot_params(value)
        return unless value.present?

        { name: 'nombre', size: 'tamaño' }.each do |k, v|
          next unless value.downcase.start_with?("#{v} alícuota ", "#{v} alicuota ")

          n = value.split(' ').last
          return [:aliquots, n.to_sym, k.to_sym]
        end

        nil
      end

      def extract_headers(row, mode = 'admin')
        headers = []
        wrong_headers = []
        row.each do |header|
          header = header&.downcase
          translation = params_translations[mode][header]
          translation ||= translate_dynamic_aliquot_params(header)

          if translation.present?
            headers << translation
          else
            wrong_headers << header
          end
        end

        @errors << I18n.t('errors.importers.subproperties.wrong_headers', wrong_headers: wrong_headers.join(', ')) if wrong_headers.present?
        return nil if @errors.present?

        headers
      end

      def extract_row(row, headers)
        params_hash = {}

        headers.each_with_index do |header, col|
          cell_value = row[col].to_s.strip
          next unless cell_value != ''

          params_hash.deep_merge!(
            header.reverse.inject(cell_value) { |v, k| { k => v } }
          )
        end

        ActionController::Parameters.new(params_hash)
      end

      def extraction(file)
        total_rows = file.last_row
        mode = @file.user.admin? ? 'admin' : 'user'

        headers = extract_headers(file.row(1), mode)

        return unless headers.present?

        (2..total_rows).each do |row|
          params = extract_row(file.row(row), headers)
          break unless params.present?

          @data_array << { line: row, params: params }
        end
      end

      def xlsx_extraction
        xlsx = Roo::Excelx.new(URI.parse(@file.excel.expiring_url(60)).open.set_encoding('BINARY'), only_visible_sheets: true)
        return @errors << I18n.t('errors.importers.subproperties.file_error') unless xlsx

        extraction(xlsx)
      end

      def xls_extraction
        xls = Roo::Excel.new(URI.parse(@file.excel.expiring_url(60)).open.set_encoding('BINARY'), only_visible_sheets: true)
        return @errors << I18n.t('errors.importers.subproperties.file_error') unless xls

        extraction(xls)
      end
    end
  end
end
