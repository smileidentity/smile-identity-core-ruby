# Smile Identity RUBY Server Side [![Build Status](https://travis-ci.com/smileidentity/smile-identity-core-ruby.svg?branch=master)](https://travis-ci.com/smileidentity/smile-identity-core-ruby)

Smile Identity provides the best solutions for real time Digital KYC, identity verification, user onboarding, and user authentication across Africa. Our server side libraries make it easy to integrate us on the server-side. Since the library is server-side, you will be required to pass the images (if required) to the library.
If you haven’t already, sign up for a free Smile Identity account, which comes with Sandbox access.

Please see [CHANGELOG.md](CHANGELOG.md) for release versions and changes.

## Features

The library exposes four classes namely; the WebApi class, the IDApi class, the Signature class, and the Utilities class.

The WebApi class has the following public methods:
submit_job - handles submission of any of Smile Identity products that requires an image i.e. Enhanced KYC + SmartSelfieTM, Document Verification and SmartSelfieTM Authentication.
get_web_token - handles generation of web token, if you are using the Hosted Web Integration.

The IDApi class has the following public method:
submit_job - handles submission of Enhanced KYC and Identity Verification.

The Signature class has the following public methods:
generate_signature - generate a signature which is then passed as a signature param when making requests to the Smile Identity server
confirm_signature - ensure a response is truly from the Smile Identity server by confirming the incoming signature

The Utilities Class allows you as the Partner to have access to our general Utility functions to gain access to your data. It has the following public methods:
get_job_status - retrieve information & results of a job. Read more on job status in the Smile Identity documentation.

## Installation

View the package on [Rubygems](https://rubygems.org/gems/smile-identity-core).

Add this line to your application's Gemfile:

```ruby
gem 'smile-identity-core'
```

and require the package:

```ruby
require 'smile-identity-core'
```

Or install it to your system as:

```shell
gem install smile-identity-core
```

## License

MIT License

## Documentation

For extensive instructions on usage of the library and sample codes, please refer to the official Smile [Identity documentation](https://docs.smileidentity.com/server-to-server/ruby).

## Getting Help

For usage questions, the best resource is [our official documentation](docs.smileidentity.com). However, if you require further assistance, you can file a [support ticket via our portal](https://portal.smileidentity.com/partner/support/tickets) or visit the [contact us page](https://portal.smileidentity.com/partner/support/tickets) on our website.

## Contributing

Bug reports and pull requests are welcome on GitHub [here](https://github.com/smileidentity/smile-identity-core-ruby).
