import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="poll-tasks"
export default class extends Controller {
  initialize() {
    if (this.element.dataset.pollUrl) {
      this.pollTasks();
      this.startPolling();
    }
  }

  startPolling() {
    this.pollingInterval = setInterval(() => this.pollTasks(), 60000);
  }

  pollTasks() {
    fetch(this.element.dataset.pollUrl)
      .then((response) => {
        if (response.status === 440) {
          clearInterval(this.pollingInterval);
          window.location.reload();
        } else {
          return response.json();
        }
      })
      .then((response) => {
        if (response) {
          if (response.active_ehr_tasks) {
            document.getElementById("active-ehr-tasks-table").innerHTML = response.active_ehr_tasks;
            document.getElementById("completed-ehr-tasks-table").innerHTML = response.completed_ehr_tasks;
            document.getElementById("cancelled-ehr-tasks-table").innerHTML = response.cancelled_ehr_tasks;
            document.getElementById("active-cp-tasks-table").innerHTML = response.active_cp_tasks;
            document.getElementById("completed-cp-tasks-table").innerHTML = response.completed_cp_tasks;
            document.getElementById("cancelled-cp-tasks-table").innerHTML = response.cancelled_cp_tasks;
          }
        }
      });
  }
}
