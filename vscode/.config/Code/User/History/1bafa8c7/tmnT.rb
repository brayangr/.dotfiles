module Constants
  module FinkokResponse
    CANCEL_MOTIVES = {
      '01' => I18n.t('views.finkok_response.cancel_options.option_01'),
      '02' => I18n.t('views.finkok_response.cancel_options.option_02'),
      '03' => I18n.t('views.finkok_response.cancel_options.option_03'),
      '04' => I18n.t('views.finkok_response.cancel_options.option_04')
    }.freeze

    CANCEL_ERRORS = {
      'connection_error' => 'Error de conexión',
      'no_cancelable' => 'No es posible cancelarlo',
      '203' => 'No corresponde el RFC del Emisor y de quien solicita la cancelación',
      '205' => 'UUID No encontrado',
  }.freeze
  end
end
