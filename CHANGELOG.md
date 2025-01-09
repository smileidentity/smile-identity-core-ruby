# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [2.3.0] - 2024-12-10
### Added
- Support for Address verification 

## [2.2.5] - 2024-06-11
### Fixed
- No changes, fixed deployment issue

## [2.2.4] - 2024-06-10
### Added
- Enhanced `strict_match` functionality in AML

### Changed
- Linted the project with internal RuboCop rules

### Fixed
- Removed support for Ruby 2.5 in RuboCop configuration and the gemspec file

## [2.2.3] - 2023-10-20
### Added
- Support for Enhanced Document Verification

## [2.2.2] - 2023-10-05
### Changed
- Lint project. Enforce RuboCop rules via GitHub action

### Added
- Support for Ruby 3.2

## [2.2.1] - 2023-08-31
### Changed
- Removed the validation of `id_type` and `id_number` for Document Verification jobs

## [2.2.0] - 2023-04-05
### Added
- Support for AML check

### Changed
- Fixed business verification docstrings

## [2.1.2] - 2023-03-09
### Changed
- Fixed `get_web_token` by ensuring signature merges into request_params

## [2.1.1] - 2022-12-13
### Added
- UPDATE_PHOTO and COMPARE_USER_INFO to JobType

### Changed
- Fixed incorrect constant values for JobType SMART_SELFIE_AUTHENTICATION and SMART_SELFIE_REGISTRATION

## [2.1.0] - 2022-10-28
### Changed
- Moved Business verification to IDApi

## [2.0.0] - 2022-10-24
### Added
- Support for Ruby 3.1
- "Examples" folder in documentation
- Business Verification product

### Changed
- Transition from TravisCI to GitHub Actions
- Enforced the use of signature on all API calls
- Added helper constants SMILE_IDENTITY_CORE::ENV, SMILE_IDENTITY_CORE::ImageType, SMILE_IDENTITY_CORE::JobType
- Fixed invalid links in gemspec

### Removed
- Support for Ruby 2.5.1
- `sec_key` as an authentication method

## [1.2.1] - 2021-12-02
### Changed
- Reverted changes to version SmileIdentityCore.version_as_hash
- Used hardcoded apiVersion

## [1.2.0] - 2021-10-08
### Added
- Signature option for signing requests

## [1.1.0] - 2021-09-29
### Added
- Version information from SmileIdentityCore.version_as_hash
- Changed URLs for both test and production environments

## [1.0.2] - 2020-01-16
### Added
- {"success":true,"smile_job_id":"job_id"} to the response when polling job status

## [1.0.1] - 2019-10-24
### Updated
- Removed first_name and last_name validations from ID information in Web API
- Added country, id_number, and id_type validations for ID information in ID API

## [1.0.0] - 2019-10-11
### Updated
- Amended the success response when job status is false to be a JSON String containing {"success":true,"smile_job_id":"job_id"}
- Added the ID API Class
- Added the ability to query ID API from the Web API class
- Updated the documentation

## [0.2.3] - 2019-09-17
### Changed
- Lenient decoding of the API key

## [0.2.2] - 2019-09-17
### Added
- Language to the package information

## [0.2.1] - 2019-09-05
### Added
- Support for additional formats as inputs
- Usage of the signature class in the Web API class
- Utilities class with a public `get_job_status` method on WebApi

### Updated
- Readme updates
- Updated some error messages

### Fixed
- Issue with the loss of optional_callback
- Ensured allowance for nil inputs or empty hashes for options and id_info
- Confirmation of signature when querying job status

## [0.2.0] - 2019-08-14
### Added
- Return_history and image_links features

### Removed
- Two parameters: optional_callback and return_job_status in the submit_job function in favor of an options hash

## [0.1.1] - 2019-07-23
### Added
- Additional package configurations

## [0.1.0] - 2019-07-19
### Added
- The first release version of Web API
