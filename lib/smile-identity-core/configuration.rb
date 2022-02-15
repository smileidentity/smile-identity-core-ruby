module SmileIdentityCore
  class Configuration
    attr_accessor :partner_id,
                  :default_callback,
                  :api_key,
                  :sid_server
    def initialize
      yield self if block_given?
    end
  end

  def self.configure(&block)
    @config = Configuration.new(&block)
  end

  def self.config
    @config
  end
end
