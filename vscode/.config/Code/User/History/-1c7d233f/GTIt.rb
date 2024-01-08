require 'roo'

module Importers
  module PropertyUsersAndProperties
    class DataExtractor
      def initialize(file, extension)
        @file = file
        @community = @file.community
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

      def property_user_identification_user_case
        @identity_type = Countries.get_identity_type(@community.country_code)&.first.to_s.downcase
        { @identity_type => %i[user identifications_attributes] }
      end

      def translate_property_user_params_user_case
        @translate_property_user_params_user_case ||= {
          'propiedad'           => %i[property address],
          'unidad'              => %i[property address],
          'comunidad'           => %i[community_id],
          'nombre de propiedad' => %i[property name],
          'nombre usuario'      => %i[user first_name],
          'apellido usuario'    => %i[user last_name],
          'email'               => %i[user email],
          'teléfono'            => %i[user phone],
          'a cargo'             => %i[property_user in_charge],
          'rol'                 => %i[property_user role]
        }.update(property_user_identification_user_case)
      end

      def property_user_identification_admin_case
        @identity_type = Countries.get_identity_type(@community.country_code)&.first.to_s.downcase
        { 'user[' + @identity_type + ']' => %i[user identifications_attributes] }
      end

      def translate_property_user_params_admin_case
        @translate_property_user_params_admin_case ||= {
          'community[id]'            => %i[community_id],
          'property[id]'             => %i[property id],
          'property[address]'        => %i[property address],
          'property[description]'    => %i[property description],
          'property[name]'           => %i[property name],
          'property[priority_order]' => %i[property priority_order],
          'property[size]'           => %i[property size],
          'property_user[in_charge]' => %i[property_user in_charge],
          'property_user[owner]'     => %i[property_user owner],
          'property_user[role]'      => %i[property_user role],
          'user[id]'                 => %i[user id],
          'user[first_name]'         => %i[user first_name],
          'user[last_name]'          => %i[user last_name],
          'user[mother_last_name]'   => %i[user mother_last_name],
          'user[email]'              => %i[user email],
          'user[phone]'              => %i[user phone],
          'user[country_code]'       => %i[user country_code]
        }.update(property_user_identification_admin_case).merge(translate_property_user_params_user_case)
      end

      def translate_dynamic_aliquot_params(value)
        { name: 'nombre', size: 'tamaño' }.each do |k, v|
          next unless value.downcase.start_with?("#{v} alícuota ", "#{v} alicuota ")

          n = value.split(' ').last
          return [:aliquots, n.to_sym, k.to_sym]
        end
        nil
      end

      def translate_dynamic_property_params(value)
        return unless value.downcase.start_with?('property_params')

        property_param = value.scan(/\[(.*?)\]/i).flatten.first.to_sym
        [:property_params, property_param]
      end

      def parse_params_user_case(line, headers)
        hash = {} # { user: { first_name: value1, last_name: value2, email: value3 ...} }
        headers.each_with_index do |header, column_index|
          next unless line[column_index].to_s.strip != ''

          translation = translate_property_user_params_user_case[header]
          cell_value = parse_column(line, translation, column_index)
          hash.deep_merge!(
            translation.reverse.inject(cell_value) { |a, n| { n => a } }
          )
        end
        ActionController::Parameters.new(hash)
      end

      def parse_params_admin_case(line, headers)
        hash = {}
        bad_headers = []
        headers.each_with_index do |header, column_index|
          header = header.downcase
          translation = translate_property_user_params_admin_case[header]
          translation ||= translate_dynamic_aliquot_params(header)
          translation ||= translate_dynamic_property_params(header)
          if translation.present?
            next unless line[column_index].to_s.strip != ''

            cell_value = parse_column(line, translation, column_index)
            hash.deep_merge!(
              translation.reverse.inject(cell_value) { |a, n| { n => a } }
            )
          else
            bad_headers << header
          end
        end
        @errors << I18n.t('errors.importers.property_users_and_properties.header_error', bad_headers: bad_headers.join(' - ')) if bad_headers.present?
        return nil if @errors.present?

        ActionController::Parameters.new(hash)
      end

      def parse_column(line, translation, column_index)
        cell_value = line[column_index].to_s.gsub("\302\240", ' ').strip
        cell_value.gsub!(/\.[0-9]*/, '') if translation.eql?(%i[user phone])
        cell_value = { identity: cell_value } if translation.eql?(%i[user identifications_attributes])
        cell_value
      end

      def extraction(file)
        total_rows = file.last_row
        headers = file.row(1)
        if @file.user.admin?
          2.upto(total_rows).each do |row|
            params = parse_params_admin_case(file.row(row), headers)
            break unless params.present?

            @data_array << { line: row, params: params }
          end
        else
          2.upto(total_rows).each do |row|
            params = parse_params_user_case(file.row(row), headers)
            @data_array << { line: row, params: params }
          end
        end
      end

      def xlsx_extraction
        xlsx = Roo::Excelx.new(URI.parse(@file.excel.expiring_url(60)).open.set_encoding('ASCII-8BIT'), only_visible_sheets: true)
        return @errors << I18n.t('errors.importers.property_users_and_properties.file_error') unless xlsx

        extraction(xlsx)
      end

      def xls_extraction
        xls = Roo::Excel.new(URI.parse(@file.excel.expiring_url(60)).open.set_encoding('ASCII-8BIT'), only_visible_sheets: true)
        return @errors << I18n.t('errors.importers.property_users_and_properties.file_error') unless xls

        extraction(xls)
      end
    end
  end
end
