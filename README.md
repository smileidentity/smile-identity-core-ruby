# SmileIdentityCore [![Build Status](https://travis-ci.com/smileidentity/smile-identity-core-ruby.svg?branch=master)](https://travis-ci.com/smileidentity/smile-identity-core-ruby)

The official Smile Identity gem exposes four classes namely; the Web Api class, the ID Api class, the Signature class and the Utilities class.

The **Web Api Class** allows you as the Partner to validate a user’s identity against the relevant Identity Authorities/Third Party databases that Smile Identity has access to using ID information provided by your customer/user (including photo for compare). It has the following public methods:
- submit_job
- get_job_status

The **ID Api Class** lets you performs basic KYC Services including verifying an ID number as well as retrieve a user's Personal Information. It has the following public methods:
- submit_job

The **Signature Class** allows you as the Partner to generate a sec key to interact with our servers. It has the following public methods:
- generate_sec_key
- confirm_sec_key

The **Utilities Class** allows you as the Partner to have access to our general Utility functions to gain access to your data. It has the following public methods:
- get_job_status

## Documentation

This gem requires specific input parameters, for more detail on these parameters please refer to our [documentation for Web API](https://docs.smileidentity.com).

Please note that you will have to be a Smile Identity Partner to be able to query our services. You can sign up on the [Portal](https://portal.smileidentity.com/signup).

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
$ response = connection.submit_job(partner_params, images, nil, nil);
```

In the case of a Job Type 5 you can simply omit the the images and options keys. Remember that the response is immediate, so there is no need to query the job_status. There is also no enrollment so no images are required. The response for a job type 5 can be found in the response section below.

```
$ response = connection.submit_job(partner_params, nil, id_info, nil);
```

**Response:**

Should you choose to *set return_job_status to false*, the response will be a JSON String containing:
```
{success: true, smile_job_id: smile_job_id}
```

However, if you have *set return_job_status to true (with image_links and history)* then you will receive JSON Object response like below:
```
{
   "job_success":true,
   "result":{
      "ConfidenceValue":"99",
      "JSONVersion":"1.0.0",
      "Actions":{
         "Verify_ID_Number":"Verified",
         "Return_Personal_Info":"Returned",
         "Human_Review_Update_Selfie":"Not Applicable",
         "Human_Review_Compare":"Not Applicable",
         "Update_Registered_Selfie_On_File":"Not Applicable",
         "Liveness_Check":"Not Applicable",
         "Register_Selfie":"Approved",
         "Human_Review_Liveness_Check":"Not Applicable",
         "Selfie_To_ID_Authority_Compare":"Completed",
         "Selfie_To_ID_Card_Compare":"Not Applicable",
         "Selfie_To_Registered_Selfie_Compare":"Not Applicable"
      },
      "ResultText":"Enroll User",
      "IsFinalResult":"true",
      "IsMachineResult":"true",
      "ResultType":"SAIA",
      "PartnerParams":{
         "job_type":"1",
         "optional_info":"we are one",
         "user_id":"HBBBBBBH57g",
         "job_id":"HBBBBBBHg"
      },
      "Source":"WebAPI",
      "ResultCode":"0810",
      "SmileJobID":"0000001111"
   },
   "code":"2302",
   "job_complete":true,
   "signature":"HKBhxcv+1qaLy\C7PjVtk257dE=|1577b051a4313ed5e3e4d29893a66f966e31af0a2d2f6bec2a7f2e00f2701259",
   "history":[
      {
         "ConfidenceValue":"99",
         "JSONVersion":"1.0.0",
         "Actions":{
            "Verify_ID_Number":"Verified",
            "Return_Personal_Info":"Returned",
            "Human_Review_Update_Selfie":"Not Applicable",
            "Human_Review_Compare":"Not Applicable",
            "Update_Registered_Selfie_On_File":"Not Applicable",
            "Liveness_Check":"Not Applicable",
            "Register_Selfie":"Approved",
            "Human_Review_Liveness_Check":"Not Applicable",
            "Selfie_To_ID_Authority_Compare":"Completed",
            "Selfie_To_ID_Card_Compare":"Not Applicable",
            "Selfie_To_Registered_Selfie_Compare":"Not Applicable"
         },
         "ResultText":"Enroll User",
         "IsFinalResult":"true",
         "IsMachineResult":"true",
         "ResultType":"SAIA",
         "PartnerParams":{
            "job_type":"1",
            "optional_info":"we are one",
            "user_id":"HBBBBBBH57g",
            "job_id":"HBBBBBBHg"
         },
         "Source":"WebAPI",
         "ResultCode":"0810",
         "SmileJobID":"0000001111"
      }
   ],
   "image_links":{
      "selfie_image":"image_link"
   },
   "timestamp":"2019-10-10T12:32:04.622Z"
}
```

You can also *view your response asynchronously at the callback* that you have set, it will look as follows:
```
{
   "job_success":true,
   "result":{
      "ConfidenceValue":"99",
      "JSONVersion":"1.0.0",
      "Actions":{
         "Verify_ID_Number":"Verified",
         "Return_Personal_Info":"Returned",
         "Human_Review_Update_Selfie":"Not Applicable",
         "Human_Review_Compare":"Not Applicable",
         "Update_Registered_Selfie_On_File":"Not Applicable",
         "Liveness_Check":"Not Applicable",
         "Register_Selfie":"Approved",
         "Human_Review_Liveness_Check":"Not Applicable",
         "Selfie_To_ID_Authority_Compare":"Completed",
         "Selfie_To_ID_Card_Compare":"Not Applicable",
         "Selfie_To_Registered_Selfie_Compare":"Not Applicable"
      },
      "ResultText":"Enroll User",
      "IsFinalResult":"true",
      "IsMachineResult":"true",
      "ResultType":"SAIA",
      "PartnerParams":{
         "job_type":"1",
         "optional_info":"we are one",
         "user_id":"HBBBBBBH57g",
         "job_id":"HBBBBBBHg"
      },
      "Source":"WebAPI",
      "ResultCode":"0810",
      "SmileJobID":"0000001111"
   },
   "code":"2302",
   "job_complete":true,
   "signature":"HKBhxcv+1qaLy\C7PjVtk257dE=|1577b051a4313ed5e3e4d29893a66f966e31af0a2d2f6bec2a7f2e00f2701259",
   "history":[
      {
         "ConfidenceValue":"99",
         "JSONVersion":"1.0.0",
         "Actions":{
            "Verify_ID_Number":"Verified",
            "Return_Personal_Info":"Returned",
            "Human_Review_Update_Selfie":"Not Applicable",
            "Human_Review_Compare":"Not Applicable",
            "Update_Registered_Selfie_On_File":"Not Applicable",
            "Liveness_Check":"Not Applicable",
            "Register_Selfie":"Approved",
            "Human_Review_Liveness_Check":"Not Applicable",
            "Selfie_To_ID_Authority_Compare":"Completed",
            "Selfie_To_ID_Card_Compare":"Not Applicable",
            "Selfie_To_Registered_Selfie_Compare":"Not Applicable"
         },
         "ResultText":"Enroll User",
         "IsFinalResult":"true",
         "IsMachineResult":"true",
         "ResultType":"SAIA",
         "PartnerParams":{
            "job_type":"1",
            "optional_info":"we are one",
            "user_id":"HBBBBBBH57g",
            "job_id":"HBBBBBBHg"
         },
         "Source":"WebAPI",
         "ResultCode":"0810",
         "SmileJobID":"0000001111"
      }
   ],
   "image_links":{
      "selfie_image":"image_link"
   },
   "timestamp":"2019-10-10T12:32:04.622Z"
}
```

If you have queried a job type 5, your response be a JSON String that will contain the following:
```
{
   "JSONVersion":"1.0.0",
   "SmileJobID":"0000001105",
   "PartnerParams":{
      "user_id":"T6yzdOezucdsPrY0QG9LYNDGOrC",
      "job_id":"FS1kd1dd15JUpd87gTBDapvFxv0",
      "job_type":5
   },
   "ResultType":"ID Verification",
   "ResultText":"ID Number Validated",
   "ResultCode":"1012",
   "IsFinalResult":"true",
   "Actions":{
      "Verify_ID_Number":"Verified",
      "Return_Personal_Info":"Returned"
   },
   "Country":"NG",
   "IDType":"PASSPORT",
   "IDNumber":"A04150107",
   "ExpirationDate":"2017-10-28",
   "FullName":"ADEYEMI KEHINDE ADUNOLA",
   "DOB":"1989-09-20",
   "Photo":"SomeBase64Image",
   "sec_key":"pjxsxEY69zEHjSPFvPEQTqu17vpZbw+zTNqaFxRWpYDiO+7wzKc9zvPU2lRGiKg7rff6nGPBvQ6rA7/wYkcLrlD2SuR2Q8hOcDFgni3PJHutij7j6ThRdpTwJRO2GjLXN5HHDB52NjAvKPyclSDANHrG1qb/tloO7x4bFJ7tKYE=|8faebe00b317654548f8b739dc631431b67d2d4e6ab65c6d53539aaad1600ac7",
   "timestamp":1570698930193
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

**Response**

Your response will return a JSON Object below with image_links and history included:

```
{
   "job_success":true,
   "result":{
      "ConfidenceValue":"99",
      "JSONVersion":"1.0.0",
      "Actions":{
         "Verify_ID_Number":"Verified",
         "Return_Personal_Info":"Returned",
         "Human_Review_Update_Selfie":"Not Applicable",
         "Human_Review_Compare":"Not Applicable",
         "Update_Registered_Selfie_On_File":"Not Applicable",
         "Liveness_Check":"Not Applicable",
         "Register_Selfie":"Approved",
         "Human_Review_Liveness_Check":"Not Applicable",
         "Selfie_To_ID_Authority_Compare":"Completed",
         "Selfie_To_ID_Card_Compare":"Not Applicable",
         "Selfie_To_Registered_Selfie_Compare":"Not Applicable"
      },
      "ResultText":"Enroll User",
      "IsFinalResult":"true",
      "IsMachineResult":"true",
      "ResultType":"SAIA",
      "PartnerParams":{
         "job_type":"1",
         "optional_info":"we are one",
         "user_id":"HBBBBBBH57g",
         "job_id":"HBBBBBBHg"
      },
      "Source":"WebAPI",
      "ResultCode":"0810",
      "SmileJobID":"0000001111"
   },
   "code":"2302",
   "job_complete":true,
   "signature":"HKBhxcv+1qaLy\C7PjVtk257dE=|1577b051a4313ed5e3e4d29893a66f966e31af0a2d2f6bec2a7f2e00f2701259",
   "history":[
      {
         "ConfidenceValue":"99",
         "JSONVersion":"1.0.0",
         "Actions":{
            "Verify_ID_Number":"Verified",
            "Return_Personal_Info":"Returned",
            "Human_Review_Update_Selfie":"Not Applicable",
            "Human_Review_Compare":"Not Applicable",
            "Update_Registered_Selfie_On_File":"Not Applicable",
            "Liveness_Check":"Not Applicable",
            "Register_Selfie":"Approved",
            "Human_Review_Liveness_Check":"Not Applicable",
            "Selfie_To_ID_Authority_Compare":"Completed",
            "Selfie_To_ID_Card_Compare":"Not Applicable",
            "Selfie_To_Registered_Selfie_Compare":"Not Applicable"
         },
         "ResultText":"Enroll User",
         "IsFinalResult":"true",
         "IsMachineResult":"true",
         "ResultType":"SAIA",
         "PartnerParams":{
            "job_type":"1",
            "optional_info":"we are one",
            "user_id":"HBBBBBBH57g",
            "job_id":"HBBBBBBHg"
         },
         "Source":"WebAPI",
         "ResultCode":"0810",
         "SmileJobID":"0000001111"
      }
   ],
   "image_links":{
      "selfie_image":"image_link"
   },
   "timestamp":"2019-10-10T12:32:04.622Z"
}
```

#### ID Api Class


##### submit_job method
```
$ connection = SmileIdentityCore::IDApi.new(partner_id, api_key, sid_server)

$ response = connection.submit_job(partner_params, id_info)
```

**Response**

Your response will return a JSON String containing the below:
```
{
   "JSONVersion":"1.0.0",
   "SmileJobID":"0000001105",
   "PartnerParams":{
      "user_id":"T6yzdOezucdsPrY0QG9LYNDGOrC",
      "job_id":"FS1kd1dd15JUpd87gTBDapvFxv0",
      "job_type":5
   },
   "ResultType":"ID Verification",
   "ResultText":"ID Number Validated",
   "ResultCode":"1012",
   "IsFinalResult":"true",
   "Actions":{
      "Verify_ID_Number":"Verified",
      "Return_Personal_Info":"Returned"
   },
   "Country":"NG",
   "IDType":"PASSPORT",
   "IDNumber":"A04150107",
   "ExpirationDate":"2017-10-28",
   "FullName":"ADEYEMI KEHINDE ADUNOLA",
   "DOB":"1989-09-20",
   "Photo":"SomeBase64Image",
   "sec_key":"pjxsxEY69zEHjSPFvPEQTqu17vpZbw+zTNqaFxRWpYDiO+7wzKc9zvPU2lRGiKg7rff6nGPBvQ6rA7/wYkcLrlD2SuR2Q8hOcDFgni3PJHutij7j6ThRdpTwJRO2GjLXN5HHDB52NjAvKPyclSDANHrG1qb/tloO7x4bFJ7tKYE=|8faebe00b317654548f8b739dc631431b67d2d4e6ab65c6d53539aaad1600ac7",
   "timestamp":1570698930193
}
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

```ruby
utilities_connection = SmileIdentityCore::Utilities.new('partner_id', 'api_key' , sid_server)

utilities_connection.get_job_status('user_id', 'job_id', options)
where options is {return_history: true | false, return_image_links: true | false}
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

You can use `bundle console` and then call the necessary classes with their parameters.

## Testing

Run `bundle exec rspec` to run the tests.
After running your tests open the coverage/index.html to view the test coverage

## Deployment

To release a new version:
- Update the version number in `version.rb`
- Run `gem build smile-identity-core.gemspec`
- Thereafter `gem push smile-identity-core-<version>.gem`.

Make sure to git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/smileidentity/smile-identity-core
