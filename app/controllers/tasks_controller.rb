class TasksController < ApplicationController
  before_action :require_cp_client
  before_action :get_all_supporting_resources, only: [:create]

  def update_task
    cached_cp_tasks = Rails.cache.read("cp_tasks")
    cached_ehr_tasks = Rails.cache.read("ehr_tasks")
    task_result = ""
    sr_result = ""
    begin
      task = FHIR::Task.read(params[:id])
      sr_id = task.focus&.reference&.split("/")&.last
      service_request = FHIR::ServiceRequest.read(sr_id)
      if task.present?
        part_of_id = task.partOf&.first&.reference&.split("/")&.last
        task.status = params[:status]
        task_result = task.update
        if params[:status] == "accepted" && part_of_id.present?
          # if the cp task is accepted, mark the ehr task as in-progress
          ehr_task = FHIR::Task.read(part_of_id)
          ehr_task.status = "in-progress"
          result = ehr_task.update
        elsif params[:status] == "accepted" && part_of_id.blank?
          # if the ehr task is accepted, create the cp task and service request
          create_cp_task_service_request(task_result, service_request)
        end

        if (params[:status] == "canceled" || params[:status] == "rejected") && part_of_id.present?
          # if the cp task is canceled/rejected, mark the ehr task as canceled/rejected
          service_request.status = "revoked"
          sr_result = service_request.update
          ehr_task = FHIR::Task.read(part_of_id)
          ehr_task.status = params[:status]
          ehr_task_result = ehr_task.update
        end

        if params[:status] == "completed" && part_of_id.present?
          # if the cp task is completed, mark the ehr task as completed
          cached_ehr_task = cached_ehr_tasks.find { |t| t.id == part_of_id }
          fhir_ehr_task = cached_ehr_task&.fhir_resource
          fhir_ehr_task&.status = "completed"
          result = fhir_ehr_task&.update
        end

        flash[:success] = "Task has been marked as #{params[:status]}."
      else
        flash[:error] = "Unable to update task: task not found"
      end
    rescue => e
      flash[:error] = "Unable to update task: #{e.message}"
    end
    Rails.cache.delete("cp_tasks")
    Rails.cache.delete("ehr_tasks")
    tab = task_result&.partOf&.present? ? "our-tasks" : "service-requests"
    set_active_tab(tab)
    redirect_to dashboard_path
  end

  def poll_tasks
    if !cp_client_connected?
      render json: { error: "Session expired" }, status: 440 and return
    end
    saved_cp_tasks = Rails.cache.read("cp_tasks") || []
    saved_ehr_tasks = Rails.cache.read("ehr_tasks") || []
    saved_tasks = [saved_cp_tasks, saved_ehr_tasks].flatten
    Rails.cache.delete("cp_tasks")
    Rails.cache.delete("ehr_tasks")
    success, result = fetch_tasks

    if success
      @active_cp_tasks = result["cp_tasks"]&.dig("active") || []
      @completed_cp_tasks = result["cp_tasks"]&.dig("completed") || []
      @canceled_cp_tasks = result["cp_tasks"]&.dig("canceled") || []
      @active_ehr_tasks = result["ehr_tasks"]&.dig("active") || []
      @completed_ehr_tasks = result["ehr_tasks"]&.dig("completed") || []
      @canceled_ehr_tasks = result["ehr_tasks"]&.dig("canceled") || []
      new_cp_tasks = Rails.cache.read("cp_tasks") || []
      new_ehr_tasks = Rails.cache.read("ehr_tasks") || []
      new_taks_list = [new_cp_tasks, new_ehr_tasks].flatten
      # check if any active tasks have changed status
      updated_tasks = new_taks_list.map do |referral|
        saved_task = saved_tasks.find { |task| task.id == referral.id }
        if saved_task && saved_task.status != referral.status
          referral
        else
          nil
        end
      end.compact
      task_names = updated_tasks.map { |t| t.focus&.description }.join(", ")
      task_status = updated_tasks.map { |t| t.status }.join(", ")
      flash[:success] = "#{task_names} status has been updated to #{task_status}" if updated_tasks.present?
    else
      Rails.logger.error("Unable to fetch tasks: #{result}")
    end
    render json: {
      active_cp_tasks: render_to_string(partial: "dashboard/cp_tasks_table", locals: { referrals: @active_cp_tasks, type: "active" }),
      completed_cp_tasks: render_to_string(partial: "dashboard/cp_tasks_table", locals: { referrals: @completed_cp_tasks, type: "completed" }),
      canceled_cp_tasks: render_to_string(partial: "dashboard/cp_tasks_table", locals: { referrals: @canceled_cp_tasks, type: "cancelled" }),
      active_ehr_tasks: render_to_string(partial: "dashboard/ehr_tasks_table", locals: { referrals: @active_ehr_tasks, type: "active" }),
      completed_ehr_tasks: render_to_string(partial: "dashboard/ehr_tasks_table", locals: { referrals: @completed_ehr_tasks, type: "completed" }),
      canceled_ehr_tasks: render_to_string(partial: "dashboard/ehr_tasks_table", locals: { referrals: @canceled_ehr_tasks, type: "cancelled" }),
      flash: flash[:success],
    }
    flash.discard
    # render partial: "action_steps/table", locals: { referrals: @active_referrals, type: "active" }
  end

  private

  def create_cp_task_service_request(ehr_task, ehr_request)
    # Creating CP request
    cp_request = ehr_request
    cp_request.basedOn = [{ reference: "ServiceRequest/#{ehr_request.id}" }]
    cp_request.intent = "original-order"
    cp_request.id = nil
    result_cp_request = cp_request.create
    # Creating CP task
    cp_task = ehr_task
    cp_task.partOf = [{ reference: "Task/#{ehr_task.id}" }]
    cp_task.status = "received"
    cp_task.authoredOn = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.%3NZ")
    # TODO cp_task.requester = {reference: "Organization/#{current_user.id}", display: current_user.name}
    cp_task.requester = {
      "reference": "Organization/SDOHCC-OrganizationCoordinationPlatformExample",
      "display": "ABC Coordination Platform",
    }
    cp_task.owner = {
      "reference": "Organization/SDOHCC-OrganizationClinicExample",
      "display": "Better Health Clinic",
    }
    cp_task.focus = { reference: "ServiceRequest/#{result_cp_request.id}" }
    cp_task.id = nil
    cp_task.create
  end
end
