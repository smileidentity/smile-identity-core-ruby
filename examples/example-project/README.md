# Example Project

This project is an example implementation of the Smile Identity Ruby SDK on the server side. The example implements [Enhanced KYC](https://docs.smileidentity.com/products/identity-lookup), [Biometric KYC](https://docs.smileidentity.com/products/biometric-kyc), [Document Verification](https://docs.smileidentity.com/products/document-verification) and [SmartSelfieTM Authentication](https://docs.smileidentity.com/products/biometric-authentication) job types.

## Setup

1. Run `bundle install` to install gem dependencies
2. Copy sample.env in the root folder to .env and set secrets as appropriate

```shell
cp sample.env .env
```

3. Run `ruby smart_bank.rb` to call the different job types
