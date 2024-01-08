class HeaderBoxComponent < ViewComponent::Base
  def initialize(params)
    super

    @id = params[:id] || 'header-box'
    @title = params[:title]
    @subheader = params[:subheader] || false
  end
end
