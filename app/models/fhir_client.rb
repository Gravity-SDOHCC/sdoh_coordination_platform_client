# FhirClient Model
class FhirClient < FHIR::Client
  def self.setup_client(base_url)
    client = self.new(base_url)
    client.use_r4
    client
  end
end
