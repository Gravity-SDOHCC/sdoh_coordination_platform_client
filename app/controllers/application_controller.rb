class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper

  def require_cp_client
    if cp_client_connected?
      get_cp_client
    else
      reset_session
      Rails.cache.clear
      flash[:error] = "Your session has expired. Plesase connect to a FHIR server"
      redirect_to home_path
    end
  end

  def require_ehr_client
    if ehr_client_connected?
      get_ehr_client
    else
      @fhir_ehr_client = FhirClient.setup_client(get_ehr_server_base_url)
      save_ehr_client(@fhir_ehr_client)
    end
  end
end
