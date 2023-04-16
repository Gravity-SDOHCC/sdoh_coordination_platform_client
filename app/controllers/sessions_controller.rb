class SessionsController < ApplicationController
  # Get /home
  def index
    if cp_client_connected?
      flash[:notice] = "You are already connected to a FHIR server (#{get_cp_server_base_url}). Logout to connrct to another FHIR server"
      redirect_to dashboard_path
    else
      @fhir_servers = FhirServer.all
    end
  end

  # POST /connect
  def create
    setup_clients
    # TODO: Refactor this to handle Errno::ECONNREFUSED , took too long to connect, etc. Also if-else not needed.
    begin
      capability_statement = @fhir_cp_client.capability_statement

      if capability_statement.present?
        save_cp_client(@fhir_cp_client)
        fhir_server = FhirServer.find_or_create_by(base_url: params[:fhir_server_base_url]) do |server|
          server.name = params[:fhir_server_name]
        end
        save_cp_server_base_url(fhir_server.base_url)
        save_user_id(TEST_PROVIDER_ID)

        flash[:success] = "Successfully connected to #{fhir_server.name}"
        redirect_to dashboard_path
      else
        flash[:error] = "Failed to connect to the provided CP server, verify the URL provided is correct."
        redirect_to home_path
      end
    rescue StandardError => e
      puts "Error happened:#{e.class} => #{e.message}"
      flash[:error] = "Failed to connect to the provided server, verify the URL provided is correct. Error: #{e.message}"
      redirect_to home_path
    end
  end

  # delete /disconnect
  def destroy
    reset_session
    Rails.cache.clear
    flash[:success] = "Successfully disconnected from the FHIR server"
    redirect_to root_path
  end

  private

  def setup_clients
    @fhir_cp_client = FhirClient.setup_client(params[:fhir_server_base_url])
  end
end
