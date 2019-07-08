
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "unlimit/version"

Gem::Specification.new do |spec|
  spec.name          = "unlimit"
  spec.version       = Unlimit::VERSION
  spec.authors       = ["Siddharth Gupta"]
  spec.email         = ["sids.1992@gmail.com"]

  spec.summary       = "Test your iOS projects on device despite the 100 device limit"
  spec.description   = "Test your iOS projects on device despite the 100 device limit, by switching to your personal team"
  spec.homepage      = "https://github.com/biocross/unlimit"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/biocross/unlimit"
    spec.metadata["changelog_uri"] = "https://github.com/biocross/unlimit"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.executables   = ["unlimit"]
  spec.require_paths = ["lib"]

  spec.add_dependency "xcodeproj"
  spec.add_dependency "plist"
  spec.add_dependency "fastlane"
  spec.add_dependency "configure_extensions"
  
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
end
