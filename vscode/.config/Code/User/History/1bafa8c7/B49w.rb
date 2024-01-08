module Constants
  module FinkokResponse
    CANCEL_MOTIVES = {
      '01' => I18n.t('views.finkok_response.cancel_options.option_01'),
      '02' => I18n.t('views.finkok_response.cancel_options.option_02'),
      '03' => I18n.t('views.finkok_response.cancel_options.option_03'),
      '04' => I18n.t('views.finkok_response.cancel_options.option_04')
    }.freeze

    CANCEL_ERRORS = {
      'connection_error' => I18n.t('views.finkok_response.cancel_complement_response.connection_error'),
      'no_cancelable' => I18n.t('views.finkok_response.cancel_complement_response.no_cancelable'),
      '203' => I18n.t('views.finkok_response.cancel_complement_response.connection_error'),
      '205' => 'UUID No encontrado'
    }.freeze
  end
end
