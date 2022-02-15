Dir["#{File.dirname(__FILE__)}/smile-identity-core/**/*.rb"].sort.each { |f| require(f) }

module SmileIdentityCore
  class Error < StandardError; end
end
