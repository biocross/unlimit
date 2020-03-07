# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unlimit/version'

Gem::Specification.new do |spec|
  spec.name          = 'unlimit'
  spec.version       = Unlimit::VERSION
  spec.authors       = ['Siddharth Gupta']
  spec.email         = ['sids.1992@gmail.com']

  spec.summary       = 'Test your iOS projects on device despite the 100 device limit, by automatically switching to your personal team'
  spec.description   = 'Test your iOS projects on device despite the 100 device limit, by automatically switching to your personal team'
  spec.homepage      = 'https://github.com/biocross/unlimit'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/biocross/unlimit'
    spec.metadata['changelog_uri'] = 'https://github.com/biocross/unlimit/blob/master/CHANGELOG.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.executables   = %w[unlimit unlimit-xcode]
  spec.require_paths = ['lib']

  spec.add_dependency 'xcodeproj'
  spec.add_dependency 'plist'
  spec.add_dependency 'fastlane', '>= 2.116.0'
  spec.add_dependency 'sentry-raven'
  spec.add_dependency 'configure_extensions'
  spec.add_dependency 'highline'

  spec.required_ruby_version = '>= 2.0.0'
  spec.add_development_dependency 'bundler', '>= 1.12.0'
  spec.add_development_dependency 'rake', '~> 13.0'
end
