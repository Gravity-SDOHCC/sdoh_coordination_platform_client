# Gravity SDOH Coordination Platform Client Reference Implementation

This is a reference implementation for the Coordination Platform (CP) system as defined in the [Gravity SDOHCC Implementation Guide](https://build.fhir.org/ig/HL7/fhir-sdoh-clinicalcare/CapabilityStatement-SDOHCC-CoordinationPlatform.html#title)

CPs are intermediaries who take on responsibility for managing SDOH referrals and ensuring they are executed by appropriate service delivery organizations. These systems must respond to referral fulfillment Tasks received from [Clinical Care Referral Sources](https://build.fhir.org/ig/HL7/fhir-sdoh-clinicalcare/CapabilityStatement-SDOHCC-ReferralSource.html) (e.g. EHRs) and also the initiation and management of referral fulfillment Tasks subsequently directed out to [Referral Recipients](https://build.fhir.org/ig/HL7/fhir-sdoh-clinicalcare/CapabilityStatement-SDOHCC-ReferralRecipient.html) (CBO).

## Prerequisites
- ruby 2.7.5
- postgresql
- memcache
- Node.js 14.0.0 or higher
- Yarn 1.22.0 or higher

## Built With
- Rails 7
- Bootstrap 5
- Stimulus
- ActionCable


## Running Locally
- start postgresql and memcache on your sysmtem. This is important as the app will not
run without.
- run `rake db:create` then `rake db:migrate` to create and migrate the database. This is only necessary for the first time.
- run `rails s` to start the app. The app will be availabe at http://localhost:3000

## Running with Docker
A `docker-compose.yml` is provided to build and run the app with PostgreSQL using Docker Compose.
This `docker-compose.yml`  file defines two services: `app` and `db`. The `app` ervice builds the application using the Dockerfile, exposes port 3000, and sets environment variables for the database connection. The `db` service uses the official PostgreSQL image and configures the user, password, and database name. Additionally, a named volume is used to persist PostgreSQL data.

To start the application, simply run `docker-compose up`. The app will be availabe at http://localhost:3000.

>> When editing the code, you might want to run `docker-compose build` first to rebuild the image, then run `docker-compose up`. If you are running into issues regarding assets not present in the asset pipeline, consider clearing your precompiled assets `rm -rf public/assets` and rebuilding the Docker image `docker-compose build`.

Press `control + c` or `ctrl + c` to stop the app.

## Using the App (Demo)
This CP client is configured to work with the [Gravity CP FHIR server RI](),
but can also integrate with other CP/EHR FHIR servers for testing.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
