require_relative 'lib/keycloak_3scale_users/version'

Gem::Specification.new do |spec|
  spec.name          = "keycloak_3scale_users"
  spec.version       = Keycloak3scaleUsers::VERSION
  spec.authors       = ["Abdullah Barrak"]
  spec.email         = ["abdullah@abarrak.com"]

  spec.summary       = '3scale to Keycloak users migration.'
  spec.description   = 'A CLI gem for migrating the end users accounts of 3scale to keycloak realm.'
  spec.homepage      = "https://github.com/abarrak/3scale-keycloak-users-migration"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/abarrak/3scale-keycloak-users-migration"
  spec.metadata["changelog_uri"] = "https://github.com/abarrak/3scale-keycloak-users-migration/CHANGELOG"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   << 'keycloak_3scale_users'
  spec.require_paths = ["lib"]
end
