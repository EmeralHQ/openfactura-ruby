# frozen_string_literal: true

module Openfactura
  # Electronic document resource model
  class Document
    attr_accessor :id, :dte_id, :type, :status, :folio, :issuer_rut, :receiver_rut, :amount, :tax_amount, :created_at, :updated_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @dte_id = attributes[:dte_id] || attributes[:id]
      @type = attributes[:type]
      @status = attributes[:status]
      @folio = attributes[:folio]
      @issuer_rut = attributes[:issuer_rut]
      @receiver_rut = attributes[:receiver_rut]
      @amount = attributes[:amount]
      @tax_amount = attributes[:tax_amount]
      @created_at = attributes[:created_at]
      @updated_at = attributes[:updated_at]
    end

    # Convert to hash
    def to_h
      {
        id: @id,
        dte_id: @dte_id,
        type: @type,
        status: @status,
        folio: @folio,
        issuer_rut: @issuer_rut,
        receiver_rut: @receiver_rut,
        amount: @amount,
        tax_amount: @tax_amount,
        created_at: @created_at,
        updated_at: @updated_at
      }.compact
    end
  end
end
