class OrganizationsController < ApplicationController
  before_action :require_cp_client

  def create
    org = FHIR::Organization.new(
      active: true,
      name: params[:name],
      contact: org_contact,
      address: org_address,
      type: org_type
    )
    org.create
    flash[:success] = "successfully created organization #{org.name}"
    Rails.cache.delete("organizations")
  rescue => e
    flash[:error] = "Unable to create organization"
  ensure
    redirect_to dashboard_path
  end

  private

  def org_contact
    [
      {
        telecom: [
          {
            system: "phone",
            value: params[:phone],
          },
          {
            system: "email",
            value: params[:email],
          },
          {
            system: "url",
            value: params[:url],
          },
        ],
      },
    ]
  end

  def org_address
    [
      {
        line: [params[:street]],
        city: params[:city],
        state: params[:state],
        postalCode: params[:postal_code],
      },
    ]
  end

  def org_type
    [
      {
          "coding": [
              {
                  "code": "cbo",
                  "display": "Community Based Organization",
                  "system": "http://hl7.org/gravity/CodeSystem/sdohcc-temporary-organization-type-codes"
              }
          ]
      }
    ]
  end
end
