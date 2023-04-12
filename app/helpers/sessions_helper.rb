module SessionsHelper
  DEFAULT_EHR_URL = "http://localhost:8080/fhir"
  TEST_PROVIDER_ID = "SDOHCC-OrganizationCoordinationPlatformExample".freeze

  def save_cp_client(cp_client)
    @fhir_cp_client = Rails.cache.fetch('cp_client', expires_in: 1.day) do
      cp_client
    end
  end

  def save_ehr_client(ehr_client)
    @fhir_ehr_client = Rails.cache.fetch('ehr_client', expires_in: 1.day) do
      ehr_client
    end
  end

  def get_cp_client
    @fhir_cp_client = Rails.cache.read('cp_client')
    FHIR::Model.client = @fhir_cp_client
  end

  def get_ehr_client
    @fhir_ehr_client = Rails.cache.read('ehr_client')
  end

  def cp_client_connected?
    !!Rails.cache.read('cp_client')
  end

  def ehr_client_connected?
    !!Rails.cache.read('ehr_client')
  end

  def save_cp_server_base_url(base_url)
    session[:cp_server_base_url] = base_url
  end

  def save_ehr_server_base_url(base_url)
    session[:ehr_server_base_url] = base_url
  end

  def get_cp_server_base_url
    session[:cp_server_base_url]
  end

  def get_ehr_server_base_url
    session[:ehr_server_base_url]
  end

  def save_user_id(user_id)
    session[:user_id] = user_id
  end

  def current_user_id
    session[:user_id]
  end

  def set_active_tab(tab)
    session[:active_tab] = tab
  end

  def active_tab
    session[:active_tab] || "service-requests"
  end
end
