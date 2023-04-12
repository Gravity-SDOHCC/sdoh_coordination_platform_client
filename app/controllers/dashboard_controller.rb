class DashboardController < ApplicationController
  before_action :require_cp_client, :set_tasks

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
      @completed_cp_tasks= result["cp_tasks"]&.dig("completed") || []
      @canceled_cp_tasks = result["cp_tasks"]&.dig("canceled") || []
      @active_ehr_tasks = result["ehr_tasks"]&.dig("active") || []
      @completed_ehr_tasks = result["ehr_tasks"]&.dig("completed") || []
      @canceled_ehr_tasks = result["ehr_tasks"]&.dig("canceled") || []
    else
      flash[:warning] = result
    end
  end

end
