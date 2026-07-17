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
gem "webmock", "~> 3.18"

# The linter is the one tool that does not follow the gem's Ruby floor: rubocop-shopify
# 3.0 requires Ruby >= 3.3, while this gem supports >= 3.1. Guarding it here keeps
# `bundle install` working on the 3.1 and 3.2 CI jobs — the style gate runs on 3.3 only.
# This works because Gemfile.lock is not versioned: each Ruby resolves its own set.
if RUBY_VERSION >= "3.3"
  gem "rubocop", "~> 1.72", require: false
  gem "rubocop-shopify", "~> 3.0", require: false
end
