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

  def get_cbo_organizations
    @cbo_organizations = Rails.cache.fetch("cbo", expires_in: 1.day) do
      @fhir_cp_client.read_feed(FHIR::Organization)&.resource&.entry&.map(&:resource).select { |o| o.name != "ABC Coordination Platform" }
    end
    @cbo_organizations ||= []
  end
end
