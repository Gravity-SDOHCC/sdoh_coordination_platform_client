module SessionsHelper
  DEFAULT_EHR_URL = "http://localhost:8080/fhir"
  TEST_PROVIDER_ID = "SDOHCC-OrganizationCoordinationPlatformExample".freeze

  def save_cp_client(cp_client)
    @fhir_cp_client = Rails.cache.fetch(client_key, expires_in: 1.day) do
      cp_client
    end
  end

  def get_cp_client
    @fhir_cp_client = Rails.cache.read(client_key)
  end

  def cp_client_connected?
    !!Rails.cache.read(client_key)
  end

  def clear_cache
    Rails.cache.delete(client_key)
    Rails.cache.delete(organizations_key)
    Rails.cache.delete(cp_tasks_key)
    Rails.cache.delete(ehr_tasks_key)
  end

  def save_cp_server_base_url(base_url)
    session[:cp_server_base_url] = base_url
  end

  def get_cp_server_base_url
    session[:cp_server_base_url]
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

  def session_id
    session.id
  end

  def client_key
    "#{session_id}_client"
  end

  def organizations_key
    "#{session_id}_organizations"
  end

  def cp_tasks_key
    "#{session_id}_cp_tasks"
  end

  def ehr_tasks_key
    "#{session_id}_ehr_tasks"
  end
end
