module Remuneration
  class LicenseDraftsController < ApplicationController
    load_and_authorize_resource

    def destroy
      byebug
    end
  end
end
