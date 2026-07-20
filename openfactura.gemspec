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
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  #
  # Solo se publica lo que un consumidor necesita en runtime: lib/, sig/ y la documentación de cara
  # al usuario. Todo lo de desarrollo queda fuera — este repo usa spec/, no el test/ que asumía la
  # plantilla de Bundler, así que la suite completa se estaba empaquetando (ver #13).
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[
          bin/ test/ spec/ features/ script/ docs/ .claude/ .github/
          .git appveyor Gemfile Rakefile CLAUDE.md .rubocop .rspec .ruby-lsp
        ])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  # base64 stopped being a default gem in Ruby 3.4 (it is now bundled), so a gem that requires it
  # must declare it or `require "base64"` raises LoadError outside Bundler. Used by the decode_*
  # helpers of DocumentResponse and DocumentQueryResponse.
  spec.add_dependency "base64", "~> 0.2"
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "dry-configurable", "~> 1.0"
  spec.add_dependency "zeitwerk", "~> 2.6"

  # Development dependencies live in the Gemfile, not here.
end
