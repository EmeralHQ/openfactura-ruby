# frozen_string_literal: true

module Openfactura
  # Railtie for Rails integration
  class Railtie < ::Rails::Railtie
    # Initialize configuration from Rails config
    config.before_initialize do
      if defined?(Rails) && Rails.application
        config_file = Rails.root.join("config", "initializers", "openfactura.rb")
        require config_file if File.exist?(config_file)
      end
    end

    # Setup generators
    generators do
      require_relative "../generators/openfactura/install_generator"
    end
  end
end
