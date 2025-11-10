# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
