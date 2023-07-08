# frozen_string_literal: true

require_relative 'lib/typesensual/version'

Gem::Specification.new do |spec|
  spec.name = 'typesensual'
  spec.version = Typesensual::VERSION
  spec.authors = ['Emma Lejeck']
  spec.email = ['nuck@kitsu.io']

  spec.summary = 'A simple, sensual wrapper around Typesense for Ruby'
  spec.homepage = 'https://github.com/hummingbird-me/typesensual'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/hummingbird-me/typesensual'
  spec.metadata['changelog_uri'] = 'https://github.com/hummingbird-me/typesensual/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ spec/ .git .github/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 6.1.5'
  spec.add_dependency 'paint', '>= 2.0.0'
  spec.add_dependency 'typesense', '>= 0.13.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
