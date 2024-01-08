module Remuneration
  class LicensesController < ApplicationController
    load_and_authorize_resource

    def destroy
      byebug
    end
  end
end
