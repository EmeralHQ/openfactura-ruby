# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in openfactura.gemspec
gemspec

gem "irb"
gem "rake", "~> 13.0"

# Development dependencies live here, not in the gemspec: the Shopify style guide
# enables Gemspec/DevelopmentDependencies, and a gemspec dev dep would force every
# consumer's resolution to consider tools only this repo needs.
gem "debug", "~> 1.8"
gem "factory_bot", "~> 6.2"
gem "rspec", "~> 3.12"
gem "ruby-lsp", "~> 0.15"
gem "simplecov", "~> 1.0", require: false
gem "webmock", "~> 3.18"

# railties is a dev-only dependency: it provides Rails::Railtie and Rails::Generators
# so the Railtie and install generator (the gem's Rails integration) can be tested
# without a full Rails app. It is NOT a runtime dependency of the gem.
gem "railties", "~> 8.0"

# rubocop-shopify 3.0 requires Ruby >= 3.3, which the gem's own floor now also is
# (see required_ruby_version), so no version guard is needed.
gem "rubocop", "~> 1.72", require: false
gem "rubocop-shopify", "~> 3.0", require: false
