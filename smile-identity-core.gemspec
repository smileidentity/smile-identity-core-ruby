lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "smile-identity-core/version"

Gem::Specification.new do |spec|
  spec.name          = "smile-identity-core"
  spec.version       = SmileIdentityCore::VERSION
  spec.authors       = ["Smile Identity"]
  spec.email         = ["support@smileidentity.com"]

  spec.summary       = "The Smile Identity Web API allows the user to access most of the features of the Smile Identity system through direct server to server queries."
  spec.description   = "The Official Smile Identity gem"
  spec.homepage      = "https://www.smileidentity.com/"
  spec.required_ruby_version = '>= 2.0'
  spec.license = 'MIT'

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/smileidentity/smile-identity-core-ruby"
  spec.metadata["documentation_uri"] = "https://docs.smileidentity.com"
  spec.metadata["changelog_uri"] = "https://github.com/smileidentity/smile-identity-core/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'simplecov', '~> 0.12.0'
  spec.add_development_dependency 'timecop', '~> 0.9.5'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.14.0'

  spec.add_dependency 'typhoeus', '~> 1.0', '>= 1.0.1'
  spec.add_dependency 'rubyzip', '~> 1.2', '>= 1.2.3'

end
