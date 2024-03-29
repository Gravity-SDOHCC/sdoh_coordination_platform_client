class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper

  def require_cp_client
    if cp_client_connected?
      get_cp_client
    else
      reset_session
      clear_cache
      flash[:error] = "Your session has expired. Plesase connect to a FHIR server"
      redirect_to home_path
    end
  end

  def get_cbo_organizations
    @cbo_organizations = organizations || []
  end
end
