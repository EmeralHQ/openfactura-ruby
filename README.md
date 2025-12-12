# Open Factura Ruby SDK

A Ruby gem providing a DSL interface for interacting with the Open Factura API, supporting electronic document (DTE) emission and organization management.

## Installation

### From Private GitHub Repository (Recommended)

If you're installing from a private GitHub repository, add this to your `Gemfile`:

```ruby
# Option 1: Using SSH (requires SSH key setup)
gem 'openfactura', git: 'git@github.com:EmeralHQ/openfactura-ruby.git', branch: 'main'

# Option 2: Using HTTPS with Personal Access Token
# First, create a Personal Access Token (PAT) with 'repo' scope in GitHub
# Then add to your .env or credentials:
# GITHUB_TOKEN=your_personal_access_token
gem 'openfactura', git: 'https://#{ENV["GITHUB_TOKEN"]}@github.com/EmeralHQ/openfactura-ruby.git', branch: 'main'

# Option 3: Using HTTPS with credentials in Gemfile (less secure)
# gem 'openfactura', git: 'https://username:token@github.com/EmeralHQ/openfactura-ruby.git', branch: 'main'
```

**For Rails applications**, you may need to configure Bundler to use credentials:

1. Create or edit `~/.netrc` (Linux/Mac) or `%HOME%\_netrc` (Windows):
   ```
   machine github.com
   login your_username
   password your_personal_access_token
   ```

2. Or use SSH keys (recommended):
   ```bash
   # Generate SSH key if you don't have one
   ssh-keygen -t ed25519 -C "your_email@example.com"

   # Add to GitHub: Settings > SSH and GPG keys > New SSH key
   # Then use the git@github.com URL in your Gemfile
   ```

After adding to your Gemfile:

```bash
bundle install
```

### From RubyGems (Public Release)

If the gem is published to RubyGems:

```ruby
gem 'openfactura'
```

Then execute:

```bash
bundle install
```

### Or install directly

```bash
gem install openfactura
```

## Quick Start

### Rails Integration

For Rails applications, use the generator to create the initializer:

```bash
rails generate openfactura:install
```

This creates `config/initializers/openfactura.rb` with the configuration template.

### Configuration

Edit `config/initializers/openfactura.rb` (or configure manually):

```ruby
Openfactura.configure do |config|
  # Required: Your Open Factura API key
  config.api_key = ENV.fetch("OPENFACTURA_API_KEY", "your-api-key-here")

  # Environment: :sandbox or :production (default: :sandbox)
  config.environment = Rails.env.production? ? :production : :sandbox

  # Optional: Request timeout in seconds (default: 30)
  # config.timeout = 30

  # Optional: Custom logger (default: nil, uses Rails.logger if available)
  # config.logger = Rails.logger

  # Optional: Override base URL (default: nil, uses environment-based URL)
  # config.api_base_url = nil
end
```

**Important:** Set your API key in environment variables:

```bash
# .env or .env.production
OPENFACTURA_API_KEY=your-api-key-here
```

## Usage

### Emitting DTE (Electronic Tax Documents)

The gem uses object-oriented classes to build DTE structures:

#### Basic Example

```ruby
# Build receiver
receiver = Openfactura::DSL::Receiver.new(
  rut: "76430498-5",
  business_name: "HOSTY SPA",
  business_activity: "SERVICIOS DE INFORMATICA",
  contact: "Contacto HOSTY",
  address: "ARTURO PRAT 527",
  commune: "Curicó"
)

# Build items
item = Openfactura::DSL::DteItem.new(
  line_number: 1,
  name: "Producto",
  quantity: 1,
  price: 2000,
  amount: 2000
)

# Build totals
totals = Openfactura::DSL::Totals.new(
  total_amount: 2380,
  tax_rate: "19"
)

# Build DTE
dte = Openfactura::DSL::Dte.new(
  type: 33,  # Invoice
  receiver: receiver,
  items: [item],
  totals: totals
)

# Get issuer from current organization
issuer = Openfactura.organizations.current_as_issuer

# Emit the document
response = Openfactura.documents.emit(
  dte: dte,
  issuer: issuer,
  response: ["PDF", "XML", "FOLIO", "TOKEN"]
)

# Access response
puts "Token: #{response.token}"
puts "Folio: #{response.folio}"
puts "Idempotency Key: #{response.idempotency_key}"
```

#### Using Hashes (Auto-conversion)

You can also pass hashes, and they'll be automatically converted to objects:

```ruby
dte = Openfactura::DSL::Dte.new(
  type: 33,
  receiver: {
    rut: "76430498-5",
    business_name: "HOSTY SPA",
    business_activity: "SERVICIOS DE INFORMATICA",
    contact: "Contacto HOSTY",
    address: "ARTURO PRAT 527",
    commune: "Curicó"
  },
  items: [
    {
      line_number: 1,
      name: "Producto",
      quantity: 1,
      price: 2000,
      amount: 2000
    }
  ],
  totals: {
    total_amount: 2380,
    tax_rate: "19"
  }
)

issuer = Openfactura.organizations.current_as_issuer
response = Openfactura.documents.emit(dte: dte, issuer: issuer)
```

#### Advanced Options

```ruby
response = Openfactura.documents.emit(
  dte: dte,
  issuer: issuer,
  response: ["PDF", "XML", "FOLIO", "TOKEN"],
  custom: {
    informationNote: "Nota informativa",
    paymentNote: "Pago a 30 días"
  },
  iva_exceptional: ["ARTESANO"],
  send_email: {
    to: "cliente@example.com",
    subject: "Su factura electrónica",
    body: "Adjunto encontrará su factura"
  },
  idempotency_key: "custom-key-12345"  # Optional, auto-generated if not provided
)
```

### DTE Classes

#### Dte

Main DTE class with validation:

```ruby
dte = Openfactura::DSL::Dte.new(
  type: 33,                    # Required: Valid DTE type (33, 34, 43, 46, 52, 56, 61, 110, 111, 112)
  folio: 0,                    # Optional: Defaults to 0 (auto-assigned)
  emission_date: "2024-01-15", # Optional: Defaults to today, format YYYY-MM-DD, range 2003-04-01 to 2050-12-31
  receiver: receiver,           # Required: Receiver object or hash
  items: [item1, item2],       # Required: Array of DteItem objects or hashes
  totals: totals,               # Required: Totals object or hash
  issuer: issuer,               # Optional: Issuer object or hash
  purchase_transaction_type: "1",  # Optional
  sale_transaction_type: "2",      # Optional
  payment_form: "3"                # Optional
)
```

#### Receiver

```ruby
receiver = Openfactura::DSL::Receiver.new(
  rut: "76430498-5",              # Required
  business_name: "HOSTY SPA",    # Required (automatically truncated to 100 characters)
  business_activity: "ACTIVIDADES DE CONSULTORIA",  # Required (automatically truncated to 40 characters)
  contact: "Juan Pérez",          # Required
  address: "ARTURO PRAT 527",      # Required
  commune: "Curicó"               # Required
)
```

**Note:** The `business_name` field is automatically truncated to 100 characters and `business_activity` is automatically truncated to 40 characters when converting to API format. The gem handles this truncation automatically, so you can provide longer values if needed.

#### DteItem

```ruby
item = Openfactura::DSL::DteItem.new(
  line_number: 1,           # Required
  name: "Producto",           # Required
  quantity: 1,                # Required
  price: 2000,                # Required
  description: "Descripción", # Optional
  exempt: false               # Optional: true for exempt items
)
```

#### Totals

```ruby
totals = Openfactura::DSL::Totals.new(
  total_amount: 2380,        # Required
  tax_rate: "19",            # Optional
  period_amount: 2380,       # Optional
  amount_to_pay: 2380        # Optional
)
```

#### Issuer

```ruby
issuer = Openfactura::DSL::Issuer.new(
  rut: "76795561-8",                    # Required
  business_name: "HAULMER SPA",         # Required (automatically truncated to 100 characters)
  business_activity: "VENTA AL POR MENOR",  # Required (automatically truncated to 80 characters)
  economic_activity_code: "479100",     # Required
  address: "ARTURO PRAT 527",           # Required
  commune: "Curicó",                    # Required
  sii_branch_code: "81303347",          # Optional
  phone: "+56912345678"                 # Optional
)
```

**Note:** The `business_name` field is automatically truncated to 100 characters and `business_activity` is automatically truncated to 80 characters when converting to API format. The gem handles this truncation automatically, so you can provide longer values if needed.

### Working with Organizations

```ruby
# Get current organization (based on API key)
org = Openfactura.organizations.current

# Access organization attributes
puts "RUT: #{org.rut}"
puts "Razón Social: #{org.razon_social}"
puts "Dirección: #{org.direccion}"
puts "Comuna: #{org.comuna}"
puts "Email: #{org.email}"

# Get primary economic activity
primary_activity = org.primary_activity
puts "Giro: #{primary_activity[:giro]}"
puts "Código: #{primary_activity[:codigoActividadEconomica]}"

# Convert to issuer object (recommended)
issuer = Openfactura.organizations.current_as_issuer
# Returns an Issuer object ready to use in DTE emission

# Get organization with extra fields (e.g., logo)
org_with_logo = Openfactura.organizations.current(extra_fields: "logo")

# Get organization authorized documents with available folios
documents_info = Openfactura.organizations.documents
# Returns: { rut: "...", documentos: [{ dte: "33", disponible: 100, vencimiento: "..." }, ...] }
```

### Querying Emitted Documents

The `find_by_token` method returns a `DocumentQueryResponse` object that adapts to different query types:

```ruby
# Query document JSON data (default)
response = Openfactura.documents.find_by_token(token: "token-del-documento", value: "json")
# Access document data
puts response.document.status
puts response.document.folio
puts response.document.type
# Or use the content helper
document = response.content  # Returns Document object

# Query document status
response = Openfactura.documents.find_by_token(token: "token-del-documento", value: "status")
puts response.status  # "Aceptado", "Pendiente", "Rechazado", or "Aceptado con Reparo"
puts response.document.status  # Also available via document object

# Query PDF content (base64)
response = Openfactura.documents.find_by_token(token: "token-del-documento", value: "pdf")
pdf_base64 = response.pdf  # Base64 encoded PDF string
pdf_binary = response.decode_pdf  # Decoded PDF binary data
puts response.folio  # Folio number if available

# Query XML content (base64)
response = Openfactura.documents.find_by_token(token: "token-del-documento", value: "xml")
xml_base64 = response.xml  # Base64 encoded XML string
xml_string = response.decode_xml  # Decoded XML string (handles ISO-8859-1 encoding)
puts response.folio  # Folio number if available

# Query Cedible content (base64)
response = Openfactura.documents.find_by_token(token: "token-del-documento", value: "cedible")
cedible_base64 = response.cedible  # Base64 encoded Cedible string
cedible_binary = response.decode_cedible  # Decoded Cedible binary data
puts response.folio  # Folio number if available

# Common properties available on all responses
puts response.token  # Document token
puts response.query_type  # "json", "status", "pdf", "xml", or "cedible"
puts response.has_document?  # true for "json" and "status" queries
puts response.to_h  # Convert to hash
```

#### DocumentQueryResponse Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `token` | String | Document token |
| `query_type` | String | Query type: "json", "status", "pdf", "xml", "cedible" |
| `document` | Document | Document object (for "json" and "status" queries) |
| `status` | String | Status string (for "status" query) |
| `pdf` | String | Base64 PDF content (for "pdf" query) |
| `xml` | String | Base64 XML content (for "xml" query) |
| `cedible` | String | Base64 Cedible content (for "cedible" query) |
| `folio` | Integer | Folio number (when available) |
| `content` | Mixed | Returns content based on query type |
| `has_document?` | Boolean | True if document object is available |
| `decode_pdf` | String | Decoded PDF binary data |
| `decode_xml` | String | Decoded XML string (ISO-8859-1 → UTF-8) |
| `decode_cedible` | String | Decoded Cedible binary data |
| `to_h` | Hash | Convert response to hash |

### Response Handling

The `emit` method returns a `DocumentResponse` object:

```ruby
response = Openfactura.documents.emit(dte: dte, issuer: issuer, response: ["PDF", "XML", "FOLIO", "TOKEN"])

# Available attributes
response.token           # String: Document tracking token
response.folio           # Integer: Assigned folio number
response.resolution      # Hash: Resolution date and number
response.pdf             # String: PDF in base64 (if requested)
response.xml             # String: XML in base64 (if requested)
response.stamp           # String: Stamp image in base64 (if requested)
response.logo             # String: Logo image in base64 (if requested)
response.warning         # String: Warnings (if any)
response.idempotency_key # String: Idempotency key used (generated or provided)

# Helper methods
response.success?        # Boolean: Check if emission was successful
response.decode_pdf      # Decode base64 PDF to binary
response.decode_xml      # Decode base64 XML (handles ISO-8859-1 encoding)
response.decode_stamp    # Decode base64 stamp image
response.decode_timbre    # Alias for decode_stamp (backward compatibility)
response.decode_logo     # Decode base64 logo image
response.to_h            # Convert to hash
```

## Error Handling

The gem provides comprehensive error handling with custom error classes:

```ruby
begin
  response = Openfactura.documents.emit(dte: dte, issuer: issuer)
rescue Openfactura::DocumentError => e
  # Document emission errors (OF-01, OF-02, etc.)
  puts "Error: #{e.message}"
  puts "Code: #{e.code}"
  puts "Description: #{e.error_description}"

  # Check if error has field-specific details
  if e.has_details?
    puts "Fields with errors: #{e.error_fields.join(', ')}"

    # Get details for a specific field
    field_errors = e.details_for_field("Encabezado.Emisor.RUTEmisor")
    field_errors.each do |detail|
      puts "  #{detail[:field]}: #{detail[:issue]}"
    end
  end

  # Get error description for any code
  desc = Openfactura::DocumentError.error_description("OF-01")
rescue Openfactura::AuthenticationError => e
  # Authentication failures (401)
  puts "Authentication failed"
rescue Openfactura::ValidationError => e
  # Configuration validation errors
  puts "Configuration error: #{e.message}"
rescue Openfactura::NotFoundError => e
  # Resource not found (404)
  puts "Resource not found"
rescue Openfactura::RateLimitError => e
  # Rate limit exceeded (429)
  puts "Rate limit exceeded"
rescue Openfactura::ApiError => e
  # Other API errors
  puts "API Error: #{e.message}"
  puts "Status: #{e.status_code}" if e.respond_to?(:status_code)
  puts "Response: #{e.response_body}" if e.respond_to?(:response_body)
end
```

### Error Codes

The gem includes a complete mapping of Open Factura error codes:

- **OF-01**: Faltan datos obligatorios
- **OF-02**: Faltan campos obligatorios en el dte
- **OF-03**: Validación de Permisos
- **OF-04**: Validación de Firma electrónica
- **OF-05**: Tipo Dte no soportado
- **OF-06**: Validación Idempotencia
- **OF-07**: Validación de Folios
- **OF-08**: Validación de Esquema
- **OF-09**: Validación de Relaciones
- **OF-10**: Validación de Campos
- **OF-11**: Validación de PDF
- **OF-12**: Generación XML
- **OF-13**: Error en DB
- **OF-20**: Datos de entrada incorrectos
- **OF-21**: Base de datos no disponible intente más tarde
- **OF-22**: Problema al procesar los datos
- **OF-23**: DTE no soportado (bloqueo temporal)

## Complete Example: Rails Controller

```ruby
class InvoicesController < ApplicationController
  def create
    # Build DTE from params
    dte = build_dte_from_params

    # Get issuer from current organization
    issuer = Openfactura.organizations.current_as_issuer

    # Emit document
    response = Openfactura.documents.emit(
      dte: dte,
      issuer: issuer,
      response: ["PDF", "FOLIO", "TOKEN"]
    )

    # Save to database
    invoice = Invoice.create!(
      token: response.token,
      folio: response.folio,
      pdf_base64: response.pdf,
      idempotency_key: response.idempotency_key,
      total_amount: params[:total_amount]
    )

    render json: { invoice: invoice, token: response.token }
  rescue Openfactura::DocumentError => e
    render json: {
      error: e.message,
      code: e.code,
      description: e.error_description,
      details: e.details
    }, status: :unprocessable_entity
  end

  private

  def build_dte_from_params
    Openfactura::DSL::Dte.new(
      type: 33,
      receiver: Openfactura::DSL::Receiver.new(
        rut: params[:receiver_rut],
        business_name: params[:receiver_name],
        business_activity: params[:receiver_business_activity],
        contact: params[:receiver_contact],
        address: params[:receiver_address],
        commune: params[:receiver_commune]
      ),
      items: build_items_from_params,
      totals: build_totals_from_params
    )
  end

  def build_items_from_params
    params[:items].map.with_index(1) do |item, index|
      Openfactura::DSL::DteItem.new(
        line_number: index,
        name: item[:name],
        quantity: item[:quantity],
        price: item[:price],
        amount: item[:amount]
      )
    end
  end

  def build_totals_from_params
    Openfactura::DSL::Totals.new(
      total_amount: params[:total_amount],
      tax_rate: "19"
    )
  end
end
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | String | `nil` | **Required.** Your Open Factura API key |
| `environment` | Symbol | `:sandbox` | Environment: `:sandbox` or `:production` |
| `timeout` | Integer | `30` | Request timeout in seconds |
| `logger` | Object | `nil` | Custom logger (uses Rails.logger if available) |
| `api_base_url` | String | `nil` | Override base URL (uses environment-based URL if nil) |

### Environment URLs

- **Sandbox**: `https://dev-api.haulmer.com`
- **Production**: `https://api.haulmer.com`

## Sandbox Companies

For development and testing, Open Factura provides two sandbox companies:

### Haulmer SPA
- **API Key**: `928e15a2d14d4a6292345f04960f4bd3`
- **RUT**: `76795561-8`
- **Razón Social**: `HAULMER SPA`

### Hosty SPA
- **API Key**: `41eb78998d444dbaa4922c410ef14057`
- **RUT**: `76430498-5`
- **Razón Social**: `HOSTY SPA`

You can access this data programmatically:

```ruby
require 'openfactura/sandbox_companies'

# Get Haulmer data
haulmer = Openfactura::SandboxCompanies[:haulmer]
puts haulmer[:apikey]
puts haulmer[:issuer][:rut]

# Get Hosty data
hosty = Openfactura::SandboxCompanies[:hosty]
```

## Valid DTE Types

The gem supports the following DTE types:

- **33**: Factura Electrónica
- **34**: Factura No Afecta o Exenta Electrónica
- **43**: Liquidación-Factura Electrónica
- **46**: Factura de Compra Electrónica
- **52**: Guía de Despacho Electrónica
- **56**: Nota de Débito Electrónica
- **61**: Nota de Crédito Electrónica
- **110**: Factura de Exportación
- **111**: Nota de Débito de Exportación
- **112**: Nota de Crédito de Exportación

## English-Spanish Glossary

This glossary maps Open Factura API terms (in Spanish) to the English class and method names used in this gem:

### Core Terms

| Spanish (API) | English (Gem) | Description |
|--------------|---------------|-------------|
| **Documento Tributario Electrónico (DTE)** | `Dte` | Electronic Tax Document |
| **Emisor** | `Issuer` | The company/person issuing the document |
| **Receptor** | `Receiver` | The company/person receiving the document |
| **Folio** | `folio` | Sequential number assigned to a document |
| **Timbre** | `stamp` | Digital stamp/seal on electronic documents |
| **RUT** | `rut` | Tax ID number (Rol Único Tributario) |
| **SII** | `SII` | Chilean Tax Service (Servicio de Impuestos Internos) |
| **Organización** | `Organization` | Company/organization data |

### Resource Classes

| Spanish Concept | English Class | Location |
|----------------|---------------|----------|
| Documento | `Openfactura::Document` | `lib/openfactura/resources/document.rb` |
| Respuesta de Emisión | `Openfactura::DocumentResponse` | `lib/openfactura/resources/document_response.rb` |
| Respuesta de Consulta | `Openfactura::DocumentQueryResponse` | `lib/openfactura/resources/document_query_response.rb` |
| Error de Documento | `Openfactura::DocumentError` | `lib/openfactura/resources/document_error.rb` |
| Organización | `Openfactura::Organization` | `lib/openfactura/resources/organization.rb` |

### DSL Classes

| Spanish Concept | English Class | Location |
|----------------|---------------|----------|
| DTE | `Openfactura::DSL::Dte` | `lib/openfactura/dsl/dte.rb` |
| Receptor | `Openfactura::DSL::Receiver` | `lib/openfactura/dsl/receiver.rb` |
| Item de DTE | `Openfactura::DSL::DteItem` | `lib/openfactura/dsl/dte_item.rb` |
| Totales | `Openfactura::DSL::Totals` | `lib/openfactura/dsl/totals.rb` |
| Emisor | `Openfactura::DSL::Issuer` | `lib/openfactura/dsl/issuer.rb` |

### DSL Modules

| Spanish Concept | English DSL | Location |
|----------------|-------------|----------|
| Documentos | `Openfactura.documents` | `lib/openfactura/dsl/documents.rb` |
| Organizaciones | `Openfactura.organizations` | `lib/openfactura/dsl/organizations.rb` |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/calrrox/openfactura-ruby.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## References

- [Open Factura API Documentation](https://docsapi-openfactura.haulmer.com/)
