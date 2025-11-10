# Sandbox Companies

This directory contains configuration data for sandbox companies provided by Open Factura for development and testing.

## Available Companies

### HAULMER SPA
- **RUT**: 76795561-8
- **API Key**: 928e15a2d14d4a6292345f04960f4bd3
- **Giro**: VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC
- **Actividad Económica**: 479100

### HOSTY SPA
- **RUT**: 76430498-5
- **API Key**: 41eb78998d444dbaa4922c410ef14057
- **Giro**: EMPRESAS DE SERVICIOS INTEGRALES DE INFORMÁTICA
- **Actividad Económica**: 620200

## Usage

### In Ruby code:

```ruby
require 'openfactura'

# Configure with a specific company
company = Openfactura::SandboxCompanies.configure_with(:haulmer)
# or
company = Openfactura::SandboxCompanies.configure_with(:hosty)

# Access company data
haulmer = Openfactura::SandboxCompanies[:haulmer]
puts haulmer[:apikey]
puts haulmer[:issuer][:rut]

# Get issuer data for DTE creation
issuer_data = Openfactura::SandboxCompanies[:haulmer][:issuer]
```

### In RSpec tests:

```ruby
RSpec.describe "Invoice creation", :sandbox do
  it "creates an invoice with Haulmer company" do
    # Configure with Haulmer
    Openfactura::SandboxCompanies.configure_with(:haulmer)

    invoice = Openfactura.invoices.create(
      issuer: Openfactura::SandboxCompanies[:haulmer][:issuer],
      receiver: { rut: "12345678-9" },
      items: [...]
    )
  end

  it "creates an invoice with Hosty company" do
    # Configure with Hosty
    Openfactura::SandboxCompanies.configure_with(:hosty)

    invoice = Openfactura.invoices.create(
      issuer: Openfactura::SandboxCompanies[:hosty][:issuer],
      receiver: { rut: "12345678-9" },
      items: [...]
    )
  end
end
```

## Files

- `sandbox_companies.rb` - Ruby module with company data and helper methods
- `sandbox_companies.yml` - YAML version of company data (for reference)
