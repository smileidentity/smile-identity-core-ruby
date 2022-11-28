# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## Changed
- Moved Business verification to IDApi

# [2.0.0] - 2022-10-24
### Added
- build: Adds support for ruby 3.1
- docs: adds "examples" folder
- Adds Business Verification product

### Changed
- ci: Move from TravisCI to Github Actions
- core: Enforces the use of signature on all API calls
- core: Adds helper constants SMILE_IDENTITY_CORE::ENV, SMILE_IDENTITY_CORE::IMAGE_TYPE, SMILE_IDENTITY_CORE::JOB_TYPE
- Fixes invalid links in gemspec

### Removed
- build: Drops support for ruby 2.5.1
- core: Removes support for `sec_key` as an authentication method
  
## [1.2.1] - 2021-12-02
### Changed
- Revert changes to version SmileIdentityCore.version_as_hash
- Uses hard coded apiVersion

## [1.2.0] - 2021-10-08
### Added
- Add Signature option for signing requests

## [1.1.0] - 2021-09-29
Set version information from SmileIdentityCore.version_as_hash
- Change the urls for both test and prod aa55a72d10854f05a35db4dad3ea63930e8996f6

## [1.0.2] - 2020-01-16
Add {"success":true,"smile_job_id":"job_id"} to the response when we poll job status too

## [1.0.1] - 2019-10-24
## Updated
Remove first_name and last_name validations from id information in Web Api
Add country, id_number and id_type validations for id information in ID Api

## [1.0.0] - 2019-10-11
## Updated
Amend the success response when job status is false to be a JSON String containing {"success":true,"smile_job_id":"job_id"}
Add the ID API Class
Add the ability to query ID Api from the Web API class
Update the documentation

## [0.2.3] - 2019-09-17
### Changed
- Lenient Decoding of the api key

## [0.2.2] - 2019-09-17
### Added
- Add the language to the package information

## [0.2.1] - 2019-09-05

### Added
- Accept more formats as inputs
- Use the signature class in the Web API class
- Add a Utilities class with get_job_status that we use internally to expose a public get_job_status method on WebApi

### Updated
- Updates to the readme
- Update some error messages

### Fixed
- Fix the loss of optional_callback
- Ensure that we allow nil inputs or empty hashes for options and id_info
- Confirm the signature when querying the job status

## [0.2.0] - 2019-08-14
### Added
- Introduced return_history and image_links

### Removed
- Removed two parameters: optional_callback and return_job_status in the submit_job function in favour of an options hash.

## [0.1.1] - 2019-07-23
### Added
- Some package configurations were added.

## [0.1.0] - 2019-07-19
### Added
- The first release version of Web Api.
