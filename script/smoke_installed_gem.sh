#!/usr/bin/env bash
# Smoke test del .gem publicable: lo instala fuera del repo y sin Bundler, y ejercita el código que
# depende de gemas runtime. Es el único lugar donde se prueba lo que recibe un consumidor real:
# `bundle exec rspec` corre con el Gemfile de desarrollo, que le presta gemas que el gem no declara.
#
# No basta con `require "openfactura"`: Zeitwerk carga en forma diferida, así que los archivos de
# resources/ (y sus requires) no se ejecutan hasta que se referencia la constante. Por eso acá se
# instancian las clases y se llama a los decode_*.
set -euo pipefail

GEM_FILE="$(ls "${GITHUB_WORKSPACE:-$PWD}"/pkg/openfactura-*.gem)"
gem install --no-document "$GEM_FILE"

cd "$(mktemp -d)"
unset BUNDLE_GEMFILE RUBYOPT

ruby -e '
  require "openfactura"
  puts "openfactura #{Openfactura::VERSION} on ruby #{RUBY_VERSION}"

  # Fuerza la carga diferida de resources/ y ejercita las gemas runtime (base64).
  emitted = Openfactura::DocumentResponse.new(PDF: ["%PDF-1.4"].pack("m0"))
  raise "decode_pdf devolvió #{emitted.decode_pdf.inspect}" unless emitted.decode_pdf == "%PDF-1.4"

  queried = Openfactura::DocumentQueryResponse.new(
    token: "t", query_type: "pdf", response_data: ["%PDF-1.4"].pack("m0")
  )
  raise "decode_pdf devolvió #{queried.decode_pdf.inspect}" unless queried.decode_pdf == "%PDF-1.4"

  puts "decode_* OK sin Bundler"
'
