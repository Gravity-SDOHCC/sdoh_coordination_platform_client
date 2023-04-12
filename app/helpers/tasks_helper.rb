module TasksHelper
  include SessionsHelper

  def save_cp_tasks(tasks)
    Rails.cache.write("cp_tasks", tasks, expires_in: 1.day)
  end

  def save_ehr_tasks(tasks)
    Rails.cache.write("ehr_tasks", tasks, expires_in: 1.day)
  end

  def fetch_tasks
    client = get_cp_client
    search_params = {
      parameters: {
        _profile: "http://hl7.org/fhir/us/sdoh-clinicalcare/StructureDefinition/SDOHCC-TaskForReferralManagement",
        _sort: "-_lastUpdated",
        _include: "Task:focus",
      # _include: "ServiceRequest:supporting-info"
      },
    }

    begin
      response = client.search(FHIR::Task, search: search_params)
      if response.response[:code] == 200
        entries = response.resource.entry.map(&:resource)
        task_entries = entries.select { |entry| entry.resourceType == "Task" }
        sr_entries = entries.select { |entry| entry.resourceType == "ServiceRequest" }
        consent_entries = entries.select { |entry| entry.resourceType == "Consent" }
        if consent_entries.size == 0
          consent_entries = client.read_feed(FHIR::Consent).resource&.entry&.map(&:resource) || []
        end
        cp_tasks = []
        ehr_tasks = []
        task_entries.each do |task|
          focus_id = task.focus.reference.split("/").last
          focus = sr_entries.find { |sr| sr.id == focus_id }
          consent_id = focus&.supportingInfo&.first&.reference&.split("/")&.last
          consent = consent_entries.find { |consent| consent.id == consent_id }
          # byebug
          # TODO: This is temporary. with auth, the org id will be in the token and we can use it to filter
          if task.requester.reference.include?("SDOHCC-OrganizationCoordinationPlatformExample")
            cp_tasks << Task.new(task, focus, consent)
          else
            ehr_tasks << Task.new(task, focus, consent)
          end
        end

        # Group tasks by status and org requesting
        grp = { "cp_tasks" => group_tasks(cp_tasks), "ehr_tasks" => group_tasks(ehr_tasks) }
        save_cp_tasks(cp_tasks)
        save_ehr_tasks(ehr_tasks)
        [true, grp]
      else
        [false, "Failed to fetch referral tasks. Status: #{response.response[:code]} - #{response.response[:body]}"]
      end
    rescue Errno::ECONNREFUSED => e
      [false, "Connection refused. Please check FHIR server's URL #{get_ehr_base_url} is up and try again. #{e.message}"]
    rescue StandardError => e
      [false, "Something went wrong. #{e.message}"]
    end
  end

  def group_tasks(tasks)
    grp = { "active" => [], "completed" => [], "canceled" => [] }
    tasks&.each do |task|
      grp["active"] << task if task.status != "completed" && task.status != "canceled" && task.status != "rejected"
      grp["completed"] << task if task.status == "completed"
      grp["canceled"] << task if task.status == "canceled" || task.status == "rejected"
    end
    grp
  end
end
