class Task
  attr_reader :id, :status, :focus, :owner_reference, :owner_name, :requester_name,
              :requester_reference, :patient_name, :patient_reference, :outcome,
              :outcome_type, :authored_on, :fhir_resource

  def initialize(fhir_task, fhir_service_request, fhir_consent)
    @id = fhir_task.id
    @fhir_resource = fhir_task
    @status = fhir_task.status
    @focus = ServiceRequest.new(fhir_service_request) if fhir_service_request
    @owner_reference = fhir_task.owner&.reference
    @owner_name = fhir_task.owner&.display
    @requester_name = fhir_task.requester&.display
    @requester_reference = fhir_task.requester&.reference
    @outcome = get_outcome(fhir_task.output&.first)
    @consent = Consent.new(fhir_consent) if fhir_consent
    @authored_on = fhir_task.authoredOn&.to_date
    @patient_name = fhir_task.for&.display
    @patient_reference = fhir_task.for&.reference
  end

  private



  def get_outcome(outcome)
    return if outcome.nil?
    @outcome_type = outcome.type&.coding&.first&.code&.titleize
    id = outcome.valueReference&.reference.split("/").last
    fhir_outcome = FHIR::Procedure.read(id)
    # sometimes for some reason read returns FHIR::Bundle
    fhir_outcome = fhir_outcome&.resource&.entry&.first&.resource if fhir_outcome.is_a?(FHIR::Bundle)
    Procedure.new(fhir_outcome) if fhir_outcome
  end
end
