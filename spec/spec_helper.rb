# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'vcr'
require 'timecop'

SimpleCov.start do
  add_filter '/spec/'
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/mock_response"
  config.hook_into :typhoeus
  config.allow_http_connections_when_no_cassette = true
end

require 'smile-identity-core'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    Typhoeus::Expectation.clear
  end
end
