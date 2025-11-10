# frozen_string_literal: true

module Openfactura
  # Document error model
  class DocumentError < StandardError
    # Error codes mapping
    ERROR_CODES = {
      "OF-01" => "Faltan datos obligatorios",
      "OF-02" => "Faltan campos obligatorios en el dte",
      "OF-03" => "Validación de Permisos",
      "OF-04" => "Validación de Firma electrónica",
      "OF-05" => "Tipo Dte no soportado",
      "OF-06" => "Validación Idempotencia",
      "OF-07" => "Validación de Folios",
      "OF-08" => "Validación de Esquema",
      "OF-09" => "Validación de Relaciones",
      "OF-10" => "Validación de Campos",
      "OF-11" => "Validación de PDF",
      "OF-12" => "Generación XML",
      "OF-13" => "Error en DB",
      "OF-20" => "Datos de entrada incorrectos",
      "OF-21" => "Base de datos no disponible intente más tarde",
      "OF-22" => "Problema al procesar los datos",
      "OF-23" => "DTE no soportado. Se bloquea envio de RVD(ex RCOF) y la emisión de boletas, ya sea por que el usuario se encuentra emitiendo con el SII, el usuario solicito la baja o se esta corrigiendo el folio siguiente del DTE (bloqueo temporal)"
    }.freeze

    attr_reader :code, :details

    # Initialize DocumentError from API error response
    # @param attributes [Hash] Hash with error structure from API
    def initialize(attributes = {})
      error_data = attributes[:error] || attributes["error"] || attributes
      @code = error_data[:code] || error_data["code"]
      @error_message = error_data[:message] || error_data["message"] || self.class.error_description(@code)
      @details = normalize_details(error_data[:details] || error_data["details"] || [])

      # Set message for StandardError
      super(@error_message)
    end

    # Get error message (overrides StandardError#message)
    # @return [String] Error message
    def message
      @error_message || super
    end

    # Get error description for a code
    # @param code [String] Error code (e.g., "OF-01")
    # @return [String] Error description
    def self.error_description(code)
      ERROR_CODES[code] || "Unknown error code: #{code}"
    end

    # Get error description for current code
    # @return [String] Error description
    def error_description
      self.class.error_description(@code)
    end

    public :error_description

    # Get error details for a specific field
    # @param field_name [String] Field name to filter by
    # @return [Array] Array of error details for the field
    def details_for_field(field_name)
      @details.select do |detail|
        detail[:field] == field_name.to_s || detail["field"] == field_name.to_s
      end
    end

    # Check if error has details
    # @return [Boolean] True if details array is not empty
    def has_details?
      !@details.nil? && !@details.empty?
    end

    # Get all field names that have errors
    # @return [Array] Array of field names with errors
    def error_fields
      @details.map { |detail| detail[:field] || detail["field"] }.compact.uniq
    end

    # Convert to hash
    # @return [Hash] Hash with error attributes
    def to_h
      {
        message: message,
        code: @code,
        description: error_description,
        details: @details
      }.compact
    end

    # Convert to string representation
    # @return [String] Error message with code
    def to_s
      if @code
        "[#{@code}] #{message}"
      else
        message || "Document error"
      end
    end

    private

    # Normalize details array to ensure consistent structure
    # @param details [Array] Details array from API
    # @return [Array] Normalized details array
    def normalize_details(details)
      return [] unless details.is_a?(Array)

      details.map do |detail|
        {
          field: detail[:field] || detail["field"],
          issue: detail[:issue] || detail["issue"]
        }.compact
      end
    end
  end
end
