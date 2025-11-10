# frozen_string_literal: true

module Openfactura
  # Organization resource model
  class Organization
    attr_accessor :rut, :razon_social, :email, :telefono, :direccion, :cdg_sii_sucur, :glosa_descriptiva,
                  :direccion_regional, :resolucion, :nombre_fantasia, :web, :sucursales, :actividades,
                  :comuna, :ciudad

    def initialize(attributes = {})
      # Map API response fields (camelCase) to Ruby attributes (snake_case)
      # Support both symbol and string keys
      @rut = attributes[:rut] || attributes["rut"]
      @razon_social = attributes[:razonSocial] || attributes["razonSocial"] || attributes[:razon_social] || attributes["razon_social"]
      @email = attributes[:email] || attributes["email"]
      @telefono = attributes[:telefono] || attributes["telefono"]
      @direccion = attributes[:direccion] || attributes["direccion"]
      @cdg_sii_sucur = attributes[:cdgSIISucur] || attributes["cdgSIISucur"] || attributes[:cdg_sii_sucur] || attributes["cdg_sii_sucur"] || attributes[:codigo_sii_sucursal] || attributes["codigo_sii_sucursal"]
      @glosa_descriptiva = attributes[:glosaDescriptiva] || attributes["glosaDescriptiva"] || attributes[:glosa_descriptiva] || attributes["glosa_descriptiva"]
      @direccion_regional = attributes[:direccionRegional] || attributes["direccionRegional"] || attributes[:direccion_regional] || attributes["direccion_regional"]
      @resolucion = attributes[:resolucion] || attributes["resolucion"] || {}
      @nombre_fantasia = attributes[:nombreFantasia] || attributes["nombreFantasia"] || attributes[:nombre_fantasia] || attributes["nombre_fantasia"]
      @web = attributes[:web] || attributes["web"] || attributes[:website] || attributes["website"]
      @sucursales = attributes[:sucursales] || attributes["sucursales"] || []
      @actividades = attributes[:actividades] || attributes["actividades"] || []
      @comuna = attributes[:comuna] || attributes["comuna"]
      @ciudad = attributes[:ciudad] || attributes["ciudad"]
    end

    # Convert to hash
    def to_h
      {
        rut: @rut,
        razon_social: @razon_social,
        email: @email,
        telefono: @telefono,
        direccion: @direccion,
        cdg_sii_sucur: @cdg_sii_sucur,
        glosa_descriptiva: @glosa_descriptiva,
        direccion_regional: @direccion_regional,
        resolucion: @resolucion,
        nombre_fantasia: @nombre_fantasia,
        web: @web,
        sucursales: @sucursales,
        actividades: @actividades,
        comuna: @comuna,
        ciudad: @ciudad
      }.compact
    end

    # Convert to hash for DTE issuer format
    # Uses the primary activity (actividadPrincipal: true) or first activity
    def to_issuer_h
      primary_activity = self.primary_activity || {}

      # Support both symbol and string keys in activity hash
      giro = primary_activity[:giro] || primary_activity["giro"]
      codigo = primary_activity[:codigoActividadEconomica] || primary_activity["codigoActividadEconomica"] ||
               primary_activity[:codigo_actividad_economica] || primary_activity["codigo_actividad_economica"]

      {
        rut: @rut,
        razon_social: @razon_social,
        giro: giro || @glosa_descriptiva,
        actividad_economica: codigo,
        direccion: @direccion,
        comuna: @comuna,
        codigo_sii_sucursal: @cdg_sii_sucur
      }.compact
    end

    # Get primary activity
    # Supports both symbol and string keys
    def primary_activity
      @actividades.find do |a|
        a[:actividadPrincipal] == true || a["actividadPrincipal"] == true
      end || @actividades.first
    end

    # Convert to JSON
    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
