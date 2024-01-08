class PropertyUserRequestsController < ApplicationController
  load_and_authorize_resource

  before_action :set_property_user_request, only: %i[confirm reject]
  before_action :check_if_uses_period_control, only: :index

  def index
    @title = t('views.side_bar_links.resident_requests')
    @user_requests = UserRequestQueries.filter_by_community(
      current_community, request_type: params[:request_type], keywords: params[:keywords], page: params[:page]
    )
  end

  def confirm
    if @property_user_request.confirm
      flash[:notice] = I18n.t('messages.notices.property_user_request.request_accepted')
    end

    redirect_to property_user_requests_path
  end

  def reject
    flash[:notice] = I18n.t('messages.notices.property_user_request.request_rejected') if @property_user_request.reject
    redirect_to property_user_requests_path
  end

  private

  def set_property_user_request
    @property_user_request = current_community.property_user_requests.find_by_id(params[:id])
  end
end
