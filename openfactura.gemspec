# frozen_string_literal: true

require_relative "lib/openfactura/version"

Gem::Specification.new do |spec|
  spec.name = "openfactura"
  spec.version = Openfactura::VERSION
  spec.authors = ["Carlos Torrealba"]
  spec.email = ["carlos@emeral.cl"]

  spec.summary = "Ruby SDK with DSL for Open Factura API"
  spec.description = "A Ruby gem providing a DSL interface for interacting with the Open Factura API, supporting electronic document (DTE) emission and organization management."
  spec.homepage = "https://github.com/EmeralHQ/openfactura-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "dry-configurable", "~> 1.0"
  spec.add_dependency "zeitwerk", "~> 2.6"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "factory_bot", "~> 6.2"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "rubocop-rails", "~> 2.33"
  spec.add_development_dependency "rubocop-rails-omakase", "~> 1.1"
  spec.add_development_dependency "ruby-lsp", "~> 0.15"
  spec.add_development_dependency "debug", "~> 1.8"
end
