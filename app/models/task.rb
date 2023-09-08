class Task
  include ModelHelper

  attr_reader :id, :status, :focus, :owner_reference, :owner_name, :requester_name,
              :requester_resource, :patient_name, :patient_resource, :outcome, :consent,
              :outcome_type, :authored_on, :status_reason, :fhir_resource

  def initialize(fhir_task, cp_client)
    @id = fhir_task.id
    @fhir_resource = fhir_task
    @status = fhir_task.status
    sr_resource = get_fhir_resource(FHIR::ServiceRequest, fhir_task.focus, cp_client) if fhir_task.focus.present?
    @focus = ServiceRequest.new(sr_resource) if sr_resource.present?
    @owner_reference = fhir_task.owner&.reference
    @owner_name = fhir_task.owner&.display
    @requester_name = fhir_task.requester&.display
    @requester_resource =
      fhir_task.requester&.reference&.include?("Organization") ?
        get_fhir_resource(FHIR::Organization, fhir_task.requester, cp_client) :
        get_fhir_resource(FHIR::PractitionerRole, fhir_task.requester, cp_client)
    remove_client_instances(@requester_resource)
    @outcome = get_outcome(fhir_task.output&.first, cp_client)
    @consent = get_consent(@focus&.fhir_resource, cp_client)
    @authored_on = fhir_task.authoredOn&.to_date
    @status_reason = fhir_task.statusReason&.text
    @patient_name = fhir_task.for&.display
    @patient_resource = get_fhir_resource(FHIR::Patient, fhir_task.for, cp_client)
    remove_client_instances(@patient_resource)
  end

  private

  def get_outcome(outcome, cp_client)
    return if outcome.nil?

    @outcome_type = outcome.type&.coding&.first&.code&.titleize
    fhir_outcome = get_fhir_resource(FHIR::Procedure, outcome.valueReference, cp_client)
    Procedure.new(fhir_outcome) if fhir_outcome
  end

  def get_consent(focus, cp_client)
    consent_ref = focus&.supportingInfo&.first
    fhir_consent = get_fhir_resource(FHIR::Consent, consent_ref, cp_client)
    Consent.new(fhir_consent) if fhir_consent
  end

  def get_fhir_resource(fhir_class, ref, cp_client)
    resource_id = ref&.reference_id
    return if resource_id.blank?

    fhir_resource = cp_client.read(fhir_class, resource_id).resource
    # sometimes for some reason read returns FHIR::Bundle
    fhir_resource = fhir_resource&.entry&.first&.resource if fhir_resource.is_a?(FHIR::Bundle)
    fhir_resource
  end
end
