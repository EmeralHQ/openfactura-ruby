# frozen_string_literal: true

require "rubygems"

# Contratos de empaquetado. La suite normal corre bajo el Gemfile de desarrollo, que le presta al gem
# gemas que no declara: nada de acá se detecta corriendo `bundle exec rspec` sobre lib/. Estos specs
# leen el gemspec directamente, que es lo único que ve un consumidor tras `gem install`.
RSpec.describe "openfactura.gemspec" do
  subject(:gemspec) do
    Gem::Specification.load(File.expand_path("../../openfactura.gemspec", __dir__))
  end

  let(:runtime_dependencies) { gemspec.runtime_dependencies.map(&:name) }

  describe "runtime dependencies" do
    # base64 dejó de ser default gem en Ruby 3.4 y pasó a bundled: sin declararlo, un
    # `require "base64"` fuera de Bundler levanta LoadError en los decode_* (ver #13).
    it "declares base64, which lib/ requires but Ruby 3.4+ no longer provides by default" do
      expect(runtime_dependencies).to include("base64")
    end

    it "declares every third-party gem that lib/ requires unconditionally" do
      # La integración con Rails queda fuera a propósito: railtie.rb solo se carga si el consumidor ya
      # tiene Rails (ver el `if defined?(Rails)` en openfactura.rb) y lib/generators/ solo lo carga
      # `rails g` (Zeitwerk lo ignora). Declarar rails como dependencia runtime arrastraría Rails
      # entero a cada consumidor del gem, incluidos los que no usan Rails.
      files = Dir[File.expand_path("../../lib/**/*.rb", __dir__)]
        .reject { |file| file.end_with?("railtie.rb") || file.include?("/lib/generators/") }

      required = files
        .flat_map { |file| File.read(file).scan(/^\s*require "([a-z0-9_\-\/]+)"/).flatten }
        .map { |name| name.split("/").first }
        .uniq

      # Las default gems de Ruby (json, date, net/http, securerandom…) no se declaran.
      stdlib = %w[json date net securerandom logger uri time openssl]
      third_party = required - stdlib

      expect(third_party - runtime_dependencies).to be_empty,
        "requeridas en lib/ pero no declaradas en el gemspec: #{(third_party - runtime_dependencies).join(', ')}"
    end
  end

  describe "packaged files" do
    it "ships lib/" do
      expect(gemspec.files).to include("lib/openfactura.rb")
    end

    # El .gem publicado llevaba 32 archivos de spec y 15 de .claude/ contra 22 de lib/: la lista de
    # exclusión heredada de Bundler cubría test/, pero este repo usa spec/.
    it "does not ship development-only files to consumers" do
      leaked = gemspec.files.grep(%r{\A(spec|script|docs|\.claude|\.github)/|\A(CLAUDE\.md|Rakefile|\.rubocop|\.rspec|\.ruby-lsp)})

      expect(leaked).to be_empty, "archivos de desarrollo en el gem publicable: #{leaked.join(', ')}"
    end
  end
end
