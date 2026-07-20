# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Shared Emeral workflow skills for Claude Code: `branch-strategy`, `release` and `commit`
- Branching strategy doc (`docs/BRANCHING_STRATEGY.md`) and pull request template
- GitHub Actions CI (`.github/workflows/ci.yml`): RSpec on Ruby 3.3–3.5, RuboCop, and a gem
  build that installs and loads the packaged `.gem` with runtime dependencies only
- Dependabot for `github-actions` and `bundler`
- Test coverage measurement with SimpleCov and a 97% line-coverage gate enforced on CI. Line
  coverage raised from ~89% to ~98.5%, mainly across the HTTP client's error paths (429/500/timeout,
  PUT/DELETE, logging), the `ApiError`/`parse_error_body` message formatting, DSL validation-error
  messages, and the Rails install generator. Development-only change: no runtime or public API impact
- FactoryBot factories for the DSL classes (`receiver`, `issuer`, `dte_item`, `totals`, `dte`) under
  `spec/factories/`, so specs build test data with `build(:dte)` instead of repeating literals

### Changed
- Expanded `CLAUDE.md` with testing, RuboCop, backward-compatibility and secret-handling rules
- Integration specs no longer run in the default `bundle exec rspec` suite. They hit the real
  sandbox and need credentials; opt in with `RUN_INTEGRATION=1` or `--tag integration`
- RuboCop now follows the Shopify Ruby style guide (`rubocop-shopify`) instead of Omakase Rails
  (`rubocop-rails-omakase`). Development-only change: no runtime behaviour or public API is affected
- Development dependencies moved from the gemspec to the `Gemfile`, as the Shopify guide's
  `Gemspec/DevelopmentDependencies` requires. The gem's runtime dependencies are unchanged
- **Minimum Ruby raised to 3.3** (`required_ruby_version >= 3.3.0`, was `>= 3.1.0`). Ruby 3.1 and
  3.2 are both end-of-life. **Breaking for consumers still on 3.1/3.2**; with the gem in `0.x` this
  ships as a minor bump (next release: `0.2.0`)

### Removed
- `rubocop-rails` and `rubocop-rails-omakase` development dependencies, unused after the style change

### Fixed
- RuboCop never loaded its configuration: `rubocop-rails-omakase` ships a config file with no
  loadable Ruby, so `require:` raised `LoadError` and every run aborted. Now uses `inherit_gem`,
  and the 84 layout offenses it had been hiding are corrected
- `Gemfile.lock` is no longer versioned. It pinned `zeitwerk`, `activesupport`, `multi_xml` and
  `erb` to versions requiring Ruby >= 3.2, which made `bundle install` fail on Ruby 3.1 even
  though the gemspec promises `>= 3.1.0`. Each Ruby version now resolves its own set
- Dead code surfaced by the stricter style guide, with no behaviour change: a redundant
  `DocumentQueryResponse#document` that re-defined the reader already provided by `attr_accessor`,
  and a no-op constant reference in `Config.validate!`
- `Client#request` no longer swallows typed API errors: the generic `rescue StandardError` was
  catching the base `ApiError` raised for 400 and other unmapped statuses and re-wrapping it as
  `"Request failed: …"`, discarding `status_code` and `response_body`. It now re-raises any
  `Openfactura::ApiError` untouched, so those two accessors are populated on every API error (the
  error message for those statuses no longer carries the `"Request failed: "` prefix)
- `Client#request` no longer swallows programming errors. A blanket `rescue StandardError` turned
  **any** bug inside the gem — a `NoMethodError`, a `TypeError` — into a fake
  `ApiError("Request failed: …")`, so callers rescued it as a network problem while the real
  backtrace was lost. Only transport failures are translated now: timeouts stay
  `ApiError("Request timeout: …")` and connection failures (DNS, TLS, refused/reset connections)
  become `ApiError("Connection failed: …")`, both keeping the original exception as `#cause`.
  Everything else propagates untouched. **Behaviour change**: code that rescued
  `Openfactura::ApiError` to catch *all* failures will now see genuine bugs surface as themselves —
  which is the point (#12)
- `DocumentError` now inherits from `Openfactura::Error` instead of `StandardError`, so
  `rescue Openfactura::Error` catches DTE business errors alongside the rest of the hierarchy
  (`ApiError`, `ValidationError`…). Its public API (`#code`, `#details`, `#details_for_field`,
  `#error_fields`, `#to_h`, `#to_s`) is unchanged; code that rescued `StandardError` still works
- The OF-xx → `DocumentError` mapping in `emit` (`#code`, `#details`) is now proven end-to-end: with
  the 400 response body preserved, a business error now reliably raises `DocumentError` with its
  code. Added a real-HTTP regression spec (real `Client` + WebMock) since the prior test mocked the
  client and hid the gap

### Security
- Multi-tenant API key isolation: `Client` no longer configures the connection through shared
  class-level HTTParty state (`self.class.base_uri`/`headers`). Each client now holds its own
  immutable per-instance options and dispatches through HTTParty's module functions, so two clients
  built with different API keys can no longer clobber each other — a client can no longer emit DTEs
  under another tenant's credentials. Public methods (`get`/`post`/`put`/`delete`) are unchanged (#6)
- The API key and DTE body are no longer written to logs. `log_request` used to dump the full
  request options — including the `apikey` header and the DTE payload with real RUTs and amounts —
  at debug level; it now logs only method, path and non-sensitive headers, with the apikey redacted
  to `[FILTERED]` and the request body never logged (#7)

## [0.1.0] - 2025-11-10

### Added
- Initial release of Open Factura Ruby SDK
- DSL interface for interacting with Open Factura API v2
- Support for DTE (Electronic Tax Document) emission
- Object-oriented DTE creation with `Dte`, `Receiver`, `DteItem`, `Totals`, and `Issuer` classes
- Support for all DTE types (33, 34, 43, 46, 52, 56, 61, 110, 111, 112)
- DTE type validation
- Emission date validation (format YYYY-MM-DD, range 2003-04-01 to 2050-12-31)
- Automatic idempotency key generation for safe retries
- Organization management (current organization, authorized documents)
- Document querying by token
- Comprehensive error handling with custom error classes (`DocumentError`, `ApiError`, `AuthenticationError`, etc.)
- Error code mapping (OF-01 through OF-23) with descriptions
- Response handling with `DocumentResponse` class
- Base64 decoding utilities for PDF, XML, stamp, and logo
- Rails integration with Railtie and generator
- Configuration management with environment support (sandbox/production)
- Complete test suite with RSpec (130 examples, 100% passing)
- WebMock integration for API mocking in tests
- English attribute names with automatic mapping to API format
- Support for custom fields, IVA exceptional types, and email sending
- Sandbox companies helper for development and testing

### Technical Details
- Ruby 3.1+ required
- Uses Zeitwerk for automatic code loading
- Uses HTTParty for HTTP requests
- Uses dry-configurable for configuration management
- Comprehensive error handling with detailed error information
- Full test coverage with unit tests for all classes
