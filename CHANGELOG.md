# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Migrate from travis to github actions.
- Add support for ruby 3.1.
- Add "examples" folder for example implementations.

## [2.0.0] - 2022-04-28

### Added
* Added source and version number to all requests

### Changed
* Enforced the use of signature on all API calls

### Deprecated
* Removed the use of sec key on all API calls

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
### Updated
Lenient Decoding of the api key

## [0.2.2] - 2019-09-17
### Updated
Add the language to the package information

## [0.2.1] - 2019-09-05
### Updated
Updates to the readme
Update some error messages
Use the signature class in the Web API class
Accept more formats as inputs
Fix the loss of optional_callback
Ensure that we allow nil inputs or empty hashes for options and id_info
Confirm the signature when querying the job status
Add a Utilities class with get_job_status that we use internally to expose a public get_job_status method on WebApi

## [0.2.0] - 2019-08-14
### Added
Removed two parameters: optional_callback and return_job_status in the submit_job function in favour of an options hash.
Introduced return_history and image_links

## [0.1.1] - 2019-07-23
### Updated
Some package configurations were added.

## [0.1.0] - 2019-07-19
### Added
The first release version of Web Api.
