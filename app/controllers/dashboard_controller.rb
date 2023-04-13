class DashboardController < ApplicationController
  before_action :require_cp_client, :set_tasks, :get_cbo_organizations

  # GET /dashboard
  def main
    @active_tab = active_tab
  end

  private

  # Getting all resources associated with the given patient

  def set_tasks
    success, result = fetch_tasks
    if success
      @active_cp_tasks = result["cp_tasks"]&.dig("active") || []
      @completed_cp_tasks = result["cp_tasks"]&.dig("completed") || []
      @cancelled_cp_tasks = result["cp_tasks"]&.dig("cancelled") || []
      @active_ehr_tasks = result["ehr_tasks"]&.dig("active") || []
      @completed_ehr_tasks = result["ehr_tasks"]&.dig("completed") || []
      @cancelled_ehr_tasks = result["ehr_tasks"]&.dig("cancelled") || []
    else
      flash[:warning] = result
    end
  end

  def get_cbo_organizations
    @cbo_organizations = Rails.cache.fetch("cbo", expires_in: 1.day) do
      @fhir_cp_client.read_feed(FHIR::Organization)&.resource&.entry&.map(&:resource).select { |o| o.name != "ABC Coordination Platform" }
    end
    @cbo_organizations ||= []
  end
end
