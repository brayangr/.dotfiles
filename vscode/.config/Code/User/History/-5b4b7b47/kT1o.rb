class HeaderBoxComponent < ViewComponent::Base
  renders_one :title_extras
  renders_one :buttons_section

  def initialize(params)
    super

    @id = params[:id] || 'header-box'
    @title = params[:title]
    @subheader = params[:subheader] || false
  end
end
