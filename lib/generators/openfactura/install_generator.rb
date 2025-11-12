# frozen_string_literal: true

require "rails/generators"

module Openfactura
  module Generators
    # Generator to install Open Factura configuration
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("install/templates", __dir__)

      desc "Creates Open Factura configuration file"

      def create_initializer
        template "openfactura.rb.erb", "config/initializers/openfactura.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
