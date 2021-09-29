module SmileIdentityCore
  VERSION = "1.1.0"

  def self.version_as_hash
    major, minor, patch = *VERSION.split('.')
    { majorVersion: major, minorVersion: minor, buildNumber: patch }
  end
end
