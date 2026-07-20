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

    # Gemas que Ruby movió (o va a mover) de *default* a *bundled*. Mientras son default, un
    # `require` sin declararlas funciona y el gap es invisible; en cuanto pasan a bundled, el mismo
    # require levanta LoadError fuera de Bundler en la máquina del consumidor. Lista de Ruby 3.4/3.5.
    FORMERLY_DEFAULT_GEMS = %w[
      base64 bigdecimal csv drb getoptlong mutex_m nkf observer abbrev racc rinda syslog
    ].freeze

    # El chequeo va sobre esta lista y NO sobre "todo lo que no sea stdlib". Una allowlist de stdlib
    # tendría que ser exhaustiva: bastó con que otro PR agregara `require "socket"` para que este
    # spec fallara en main sin que nada estuviera realmente mal. Acá un require de stdlib nuevo no
    # puede romper nada, y la clase de bug que importa (#13) se sigue detectando.
    it "declares the formerly-default gems that lib/ requires" do
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

      undeclared = (FORMERLY_DEFAULT_GEMS & required) - runtime_dependencies

      expect(undeclared).to be_empty,
        "lib/ las requiere pero el gemspec no las declara: #{undeclared.join(', ')}. " \
          "Ruby ya no las provee por defecto: agrégalas con add_dependency o el consumidor " \
          "verá LoadError fuera de Bundler."
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
