---
name: sii-dte-formato
description: Normativa oficial del SII chileno sobre el formato de Documentos Tributarios Electrónicos (DTE) y boletas electrónicas - campos, tipos, largos, obligatoriedad, códigos (referencias, traslado, impuestos) y reglas de montos. Usar al modelar o validar campos de documentos en el gem (clases DSL), al implementar tipos de DTE nuevos (boletas 39/41, guías 52, notas 56/61, exportación) o al interpretar errores de validación de campos.
---

# Formato DTE y Boleta Electrónica (SII)

Fuente: PDFs oficiales del SII referenciados por la doc de OpenFactura. La API de OpenFactura usa exactamente estos nombres de campos y jerarquía, en JSON. Última sincronización: 2026-07-15 (skill `api-sync` para actualizar).

## Referencias

| Documento | Cubre | Archivo |
|---|---|---|
| Formato DTE (formato_dte.pdf, 49 pp.) | Facturas 33/34, liquidación 43, compra 46, guías 52, notas 56/61, exportación 110/111/112: todos los campos de Encabezado/Detalle/DscRcgGlobal/Referencia, códigos y validaciones | [references/formato-dte-sii.md](references/formato-dte-sii.md) |
| Boleta electrónica (formato_boleta_electronica.pdf **v4.2 2025-09-08** como fuente primaria; boletas_elec_020.pdf es el mismo documento en v2.22 2020-07-20) | Boletas 39 (afecta) y 41 (exenta): campos de las 7 zonas, IndServicio, montos brutos con IVA incluido, MedioPago (solo v4.2), bitácora de cambios entre versiones | [references/boleta-electronica-sii.md](references/boleta-electronica-sii.md) |

## Cuándo usar cada una

- Implementando o validando **facturas, notas de crédito/débito, guías o exportación** en el gem → `formato-dte-sii.md`.
- Implementando **boletas** (gap actual del gem: tipos 39/41 no están en `VALID_DTE_TYPES`) → `boleta-electronica-sii.md`. Regla crítica: en boletas los montos de detalle van con IVA incluido, al revés que en facturas.
- Interpretando un error `OF-10` (validación de campos) de la API → buscar el campo en la tabla correspondiente para ver formato/largo/obligatoriedad.

## Advertencias

- El SII distingue obligatoriedad: obligatorio, condicional (depende de otro campo o tipo de documento) y opcional. Las clases DSL del gem deben respetar los condicionales por tipo de DTE, no solo los obligatorios.
- OpenFactura genera por su cuenta el TED/timbre, folios y firma: el gem NUNCA debe modelar esos campos, solo los datos del documento.
- La capa API de OpenFactura añade sus propias reglas encima del SII (truncados, campos que rechaza) — la fuente para eso es el skill `openfactura-api`; este skill es la normativa de fondo.
