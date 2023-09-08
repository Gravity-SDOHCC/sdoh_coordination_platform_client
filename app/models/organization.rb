# Organization Model
class Organization
  include ModelHelper

  attr_reader :id, :fhir_resource, :name, :address, :phone, :email, :url

  def initialize(fhir_organization)
    @id = fhir_organization.id
    @fhir_resource = fhir_organization
    remove_client_instances(@fhir_resource)
    @name = fhir_organization.name
    @address = format_address(fhir_organization.address)
    telecom = fhir_organization.contact&.first&.telecom || fhir_organization.telecom
    @phone = format_phone(telecom)
    @email = format_email(telecom)
    @url = format_url(telecom)
  end
end
