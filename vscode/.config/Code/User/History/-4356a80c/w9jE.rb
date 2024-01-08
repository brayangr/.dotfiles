# frozen_string_literal: true

class ApplicationController < Jets::Controller::Base
  return nil if a
  if Jets.env.development?
    before_action :set_community
    before_action :set_locale

    def set_community
      json_params = JSON.parse(params['arguments'])
      community_id = json_params['community_id'] || json_params['_community_id']
      @community = Community.find_by(id: community_id)
    end

    def set_locale
      # en application.rb se setea el default
      # aqui vemos su posición y revisamos el idioma que corresponde
      country_code = @community&.country_code || 'es'
      language = case country_code
                when 'CL' then 'es-CL'
                when 'MX' then 'es-MX'
                when 'GT' then 'es-GT'
                when 'SV' then 'es-SV'
                when 'BO' then 'es-BO'
                when 'EC' then 'es-EC'
                when 'HN' then 'es-HN'
                when 'US' then 'en-US'
                when 'UY' then 'es-UY'
                when 'PE' then 'es-PE'
                when 'PA' then 'es-PA'
                else 'es'
                end
      I18n.locale = language
    end
  end
end
