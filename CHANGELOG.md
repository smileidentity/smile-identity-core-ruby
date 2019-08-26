# Changelog
All notable changes to this project will be documented in this file.

## [0.1.0] - 2019-07-19
### Added
The first release version of Web Api.

## [0.1.1] - 2019-07-23
### Updated
Some package configurations were added.

## [0.2.0] - 2019-08-14
### Added
Removed two parameters: optional_callback and return_job_status in the submit_job function in favour of an options hash.
Introduced return_history and image_links

## [0.2.1] - 2019-08-27
### Updated
Updates to the readme
Update some error messages
Use the signature class in the Web API class
Accept more formats as inputs
Fix the loss of optional_callback
Ensure that we allow nil inputs or empty hashes for options and id_info
Confirm the signature when querying the job status
