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
      '203' => I18n.t('views.finkok_response.cancel_complement_response.error_203'),
      '205' => I18n.t('views.finkok_response.cancel_complement_response.error_205')
    }.freeze

    COMPLEMENT_STATUS = {
      no_complement: 0,
      processing_complement: 1,
      complement_success: 2,
      complement_failed: 3,
      complement_in_queue: 4,
      cancelling_complement: 5,
      cancel_complement_failed: 6
    }.freeze
  end
end
