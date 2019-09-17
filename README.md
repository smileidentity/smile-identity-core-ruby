# SmileIdentityCore

The official Smile Identity gem exposes three classes namely, the Web API and Signature class.

The **Web API Class** allows you as the Partner to validate a user’s identity against the relevant Identity Authorities/Third Party databases that Smile Identity has access to using ID information provided by your customer/user (including photo for compare). It has the following public methods:
- submit_job
- get_job_status

The **Signature Class** allows you as the Partner to generate a sec key to interact with our servers. It has the following public methods:
- generate_sec_key
- confirm_sec_key

The **Utilities Class** allows you as the Partner to have access to our general Utility functions to gain access to your data. It has the following public methods:
- get_job_status

## Documentation

This gem requires specific input parameters, for more detail on these parameters please refer to our [documentation for Web API](https://docs-smileid.herokuapp.com/docs#web-api-introduction).

Please note that you will have to be a Smile Identity Partner to be able to query our services. You can sign up on the [Portal](https://test-smileid.herokuapp.com/signup?products[]=1-IDVALIDATION&products[]=2-AUTHENTICATION).

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

```
  $ gem install smile-identity-core
```

You now may use the classes as follows:

#### Web Api Class

##### submit_job method
```
$ connection = SmileIdentityCore::WebApi.new(partner_id, default_callback, api_key, sid_server)

$ response = connection.submit_job(partner_params, images, id_info, options)
```

Please note that if you do not need to pass through id_info or options, you may omit calling those class and send through nil in submit_job, as follows:
```
String response = connection.submit_job(partner_params, images, nil, nil);
```

The response will be nil if you chose to set return_job_status to false, however if you have set return_job_status to true then you will receive a response like below:

```
{
  "timestamp": "2018-03-13T21:04:11.193Z",
  "signature": "<your signature>",
  "job_complete": true,
  "job_success": true,
  "result": {
    "ResultText": "Enroll User",
    "ResultType": "SAIA",
    "SmileJobID": "0000001897",
    "JSONVersion": "1.0.0",
    "IsFinalResult": "true",
    "PartnerParams": {
      "job_id": "52d0de86-be3b-4219-9e96-8195b0018944",
      "user_id": "e54e0e98-8b8c-4215-89f5-7f9ea42bf650",
      "job_type": 4
    },
    "ConfidenceValue": "100",
    "IsMachineResult": "true",
  }
  "code": "2302"
}
```
You can also view your response asynchronously at the callback that you have set, it will look as follows:
```
{
  "ResultCode": "1220",
  "ResultText": "Authenticated",
  "ResultType": "DIVA",
  "SmileJobID": "0000000001",
  "JSONVersion": "1.0.0",
  "IsFinalResult": "true",
  "PartnerParams": {
    "job_id": "e7ca3e6c-e527-7165-b0b5-b90db1276378",
    "user_id": "07a0c120-98d7-4fdc-bc62-3c6bfd16c60e",
    "job_type": 2
  },
  "ConfidenceValue": "100.000000",
  "IsMachineResult": "true"
}
```

##### get_job_status method
Sometimes, you may want to get a particular job status at a later time. You may use the get_job_status function to do this:

You will already have your Web Api class initialised as follows:
```ruby
  connection = SmileIdentityCore::WebApi.new(partner_id, default_callback, api_key, sid_server)
```

Thereafter, simply call get_job_status with the correct parameters:
```ruby
  response = connection.get_job_status(partner_params, options)

  where options is {return_history: true | false, return_image_links: true | false}
```

Please note that if you do not need to pass through options if you will not be using them, you may omit pass through an empty hash or nil instead:
```ruby
response = connection.get_job_status(partner_params, nil);
```

#### Signature Class

##### generate_sec_key method

```
$ connection = SmileIdentityCore::Signature.new(partner_id, api_key)

$ sec_key = connection.generate_sec_key(timestamp)
where timestamp is optional

```

The response will be a hash:

```
{
  :sec_key=> "<the generated sec key>",
 :timestamp=> 1563283420
}
```

##### confirm_sec_key method

You can also confirm the signature that you receive when you interacting with our servers, simply use the confirm_sec_key method which returns a boolean:

```ruby
$ connection = SmileIdentityCore::Signature.new(partner_id, api_key)
$ sec_key = connection.confirm_sec_key(sec_key, timestamp)
```

#### Utilities Class

You may want to receive more information about a job. This is built into Web Api if you choose to set return_job_status as true in the options hash. However, you also have the option to build the functionality yourself by using the Utilities class. Please note that if you are querying a job immediately after submitting it, you will need to poll it for the duration of the job.

```java


utilities_connection = SmileIdentityCore::Utilities.new('partner_id', 'api_key' , sid_server)

utilities_connection.get_job_status('user_id', 'job_id', options)
where options is {return_history: true | false, return_image_links: true | false}
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version:
- Update the version number in `version.rb`
- Run `gem build smile-identity-core.gemspec`
- Thereafter `gem push smile-identity-core-version.gem`.

Make sure to git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/smileidentity/smile-identity-core
