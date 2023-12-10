# frozen_string_literal: true

require_relative "lib/shrine_storage/version"

Gem::Specification.new do |spec|
  spec.name = "shrine_storage"
  spec.version = ShrineStorage::VERSION
  spec.authors = ["Radioactive Labs"]
  # spec.email = []

  spec.summary = "A compatible ActiveStorage api for attaching Shrine uploads to ActiveRecord models"
  spec.description = "Write a longer description or delete this line."
  spec.homepage = "https://rubygems.org"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://rubygems.org"
  spec.metadata["changelog_uri"] = "https://rubygems.org"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 5.0", "< 8"
  spec.add_dependency "shrine"
  spec.add_dependency "activesupport"
  spec.add_dependency "activestorage"

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'combustion'
  spec.add_development_dependency "appraisal"


  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
