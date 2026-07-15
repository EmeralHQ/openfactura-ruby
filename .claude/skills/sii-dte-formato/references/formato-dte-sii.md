# Formato de Documentos Tributarios Electrónicos (DTE) — SII Chile

> **Fuente**: documento oficial del SII "Formato Documentos Tributarios Electrónicos",
> **Versión 2.2, fecha 2019-07-10** (48 páginas). Este archivo es una destilación fiel de ese
> PDF para uso como referencia de emisión en el SDK `openfactura-ruby`. La API de OpenFactura
> usa en JSON **los mismos nombres de campos/tags** definidos por el SII (p. ej. `RUTEmisor`,
> `MntNeto`, `IndExe`), por lo que esta referencia aplica directamente al payload JSON.

## Nota sobre esta transcripción

- Las matrices de obligatoriedad por tipo de documento fueron transcritas desde el PDF oficial.
  El PDF presenta estas matrices en tablas anchas cuya extracción de texto puede desalinear
  columnas en casos puntuales; ante una decisión límite (un `2` vs `3` en un documento poco
  común) conviene verificar contra el PDF original o el schema XSD del SII.
- Inconsistencia presente en el documento fuente: la tabla de "obligatoriedad de la zona según
  tipo de documento" (pág. 9) indica `0` (no corresponde) para la zona *Descuentos y Recargos*
  en Guía de Despacho, mientras que la tabla de campos de la sección D sí define códigos de
  obligatoriedad para la columna Guía. Se transcriben ambas tal cual.
- Las tablas de Aduana referenciadas (formas de pago de Aduana, modalidades de venta,
  cláusulas de venta, vías de transporte, unidades de medida, tipos de bulto, países y puertos)
  **no están incluidas en el PDF**; el documento remite a `www.aduana.cl`.
- La bitácora de cambios menciona el código de referencia `888: Referencia a Archivo adjunto`
  (incorporado en 2005), que no aparece en la tabla final de `TpoDocRef` de la pág. 41.

---

## 1. Documentos cubiertos y códigos de tipo de DTE (`TipoDTE`)

Documentos definidos en este formato:

| Código | Documento |
|---|---|
| 33 | Factura Electrónica |
| 34 | Factura No Afecta o Exenta Electrónica |
| 43 | Liquidación-Factura Electrónica |
| 46 | Factura de Compra Electrónica |
| 52 | Guía de Despacho Electrónica |
| 56 | Nota de Débito Electrónica |
| 61 | Nota de Crédito Electrónica |
| 110 | Factura de Exportación Electrónica |
| 111 | Nota de Débito de Exportación Electrónica |
| 112 | Nota de Crédito de Exportación Electrónica |

Otros códigos de documento que aparecen en el formato solo como **referencia** (`TpoDocRef`,
`TpoDocLiq`): 30 (factura manual), 32 (factura de venta bienes/servicios no afectos o exentos),
35 (boleta), 38 (boleta exenta), 39 (boleta electrónica), 41 (boleta exenta electrónica),
40 (liquidación factura), 45 (factura de compra manual), 50 (guía de despacho manual),
55 (nota de débito manual), 60 (nota de crédito manual), 103 (liquidación).

---

## 2. Convenciones generales del formato

### Tipos de dato y formato numérico

- **ALFA**: alfanumérico. **NUM**: numérico. El largo indicado es siempre el **largo máximo**.
- En campos numéricos los **decimales se separan con punto** y se indican **solo cuando el
  valor contiene decimales significativos**. **No se separan los miles** con carácter alguno.
- En campos alfanuméricos, los caracteres con significado especial en XML (`&`, `<`) deben
  reemplazarse por su secuencia de escape estándar.
- Fechas en formato `AAAA-MM-DD`. `FchEmis` debe ser una fecha válida entre 2003-04-01 y
  2050-12-31; la mayoría de las demás fechas (vencimiento, cancelación, referencia) entre
  2002-08-01 y 2050-12-31.
- Formato RUT (`RUTEmisor`, `RUTRecep`, etc.): cuerpo numérico entre 100.000 y 99 millones,
  guión y dígito verificador alfanumérico entre 0 y 9 o `K`. Ej: `76543210-K`.
- Desde 2005 los formatos numéricos de montos aceptan decimales para permitir documentos
  completos en moneda distinta de pesos (exportación). En pesos chilenos los montos se emiten
  como enteros.

### Códigos de obligatoriedad del SII

| Código | Significado |
|---|---|
| **0** | No corresponde. El dato **no debe ir** en ese tipo de documento. |
| **1** | **Obligatorio**. Debe estar siempre, independiente de la transacción. |
| **2** | **Condicional**. No es obligatorio en todos los documentos, pero pasa a ser obligatorio en determinadas operaciones si se cumple una condición (p. ej. si hay descuentos, deben registrarse o el documento queda descuadrado). |
| **3** | **Opcional**. |

- La columna **(\*)** marca campos cuya ausencia hace que el DTE **no se considere válidamente
  emitido y sea rechazado** por el SII. Solo existe en la zona Encabezado (más tres campos de
  Detalle). El SII **no rechaza por errores de contenido** (p. ej. IVA ≠ tasa × neto); esos
  errores se corrigen vía Nota de Crédito o Nota de Débito.
- La columna **I** indica impresión: `N` = no es obligatorio imprimirlo; `I` = debe estar
  impreso (el formato impreso puede diferir del electrónico); `P` = debe imprimirse traduciendo
  el código a su glosa (p. ej. "Factura Electrónica" en vez de 33).

### Convención de columnas de obligatoriedad usada en este documento

En las tablas siguientes, la columna **Obligatoriedad** lista 10 valores en este orden fijo
(el mismo del PDF):

```
FACT(33) - FACT.EXENTA(34) - GUIA(52) - N.CRED(61) - N.DEB(56) - FACT.COMPRA(46) - LIQ.FACT(43) - FACT.EXPO(110) - NC.EXPO(112) - ND.EXPO(111)
```

---

## 3. Zonas del documento electrónico

| Zona | Contenido |
|---|---|
| A. Encabezado | Identificación del documento (`IdDoc`), Emisor, Receptor, Transporte, Totales, Otra Moneda |
| B. Detalle por ítem | Una línea por ítem: cantidad, valor, descuentos/recargos por ítem, impuestos adicionales, valor neto. En Liquidación-Factura, datos de documentos liquidados |
| C. Subtotales informativos | Subtotales que no afectan totales ni base de impuesto |
| D. Descuentos y Recargos globales | Descuentos/recargos que afectan al total y no se especifican ítem a ítem |
| E. Información de Referencia | Documentos referenciados (guía facturada, factura corregida por NC/ND, etc.) |
| F. Comisiones y Otros Cargos | Obligatoria en Liquidación-Factura; opcional en Factura de Compra y NC/ND que corrijan operaciones de Facturas de Compra |
| G. Timbre Electrónico SII (TED) | Firma electrónica sobre datos representativos, para validar el documento impreso |
| H. Fecha y hora de firma | Timestamp de la firma electrónica |
| I. Firma Electrónica | Firma digital sobre todo el documento (integridad del DTE enviado al SII) |

**Límite estructural**: el documento no puede exceder **60 líneas de Detalle** y, si requiere
impresión, debe caber en el papel según normas del documento impreso.

### Obligatoriedad de cada zona por tipo de documento

Orden de columnas: FACT / FACT.EXENTA / GUIA / N.CRED / N.DEB / FACT.COMPRA / LIQ.FACT /
FACT.EXPO / NC.EXPO / ND.EXPO.

| Zona | Obligatoriedad |
|---|---|
| Encabezado | 1-1-1-1-1-1-1-1-1-1 |
| Detalle | 1-1-1-1-1-1-1-1-1-1 |
| Subtotales informativos | 3-3-3-3-3-3-3-3-3-3 |
| Descuentos y Recargos | 2-2-0-2-2-2-0-2-2-2 |
| Información de Referencia | 2-2-2-1-1-2-2-2-1-1 |
| Comisiones y Otros Cargos | 0-0-0-2-2-2-2-0-0-0 |
| Timbre (TED) | 1-1-1-1-1-1-1-1-1-1 |
| Fecha y hora de firma | 1-1-1-1-1-1-1-1-1-1 |
| Firma Electrónica | 1-1-1-1-1-1-1-1-1-1 |

---

## 4. A — ENCABEZADO

### 4.1 Identificación del documento — `<IdDoc>`

| # | Campo / Tag | Descripción | Tipo | Largo | (*) | I | Obligatoriedad |
|---|---|---|---|---|---|---|---|
| 1 | VERSIÓN | Versión del formato. Valor: `1.0` | ALFA | 3 | * | N | 1-1-1-1-1-1-1-1-1-1 |
| 2 | `TipoDTE` | Tipo de documento (ver tabla sección 1) | NUM | 3 | * | P | 1-1-1-1-1-1-1-1-1-1 |
| 3 | `Folio` | Folio autorizado por el SII | NUM | 10 | * | I | 1-1-1-1-1-1-1-1-1-1 |
| 4 | `FchEmis` | Fecha de emisión contable (`AAAA-MM-DD`). Válida entre 2003-04-01 y 2050-12-31 | ALFA | 10 | * | I | 1-1-1-1-1-1-1-1-1-1 |
| 5 | `IndNoRebaja` | Solo NC sin derecho a rebaja de débito. Valor `1`: NC sin derecho a descontar débito (Art. 70 DL 825 y art. 38 reglamento) | NUM | 1 | | N | 0-0-0-2-0-0-0-0-0-0 |
| 6 | `TipoDespacho` | Ver tabla 4.1.a. No se incluye si el documento no acompaña bienes o es factura/nota por servicios | NUM | 1 | | N | 2-2-2-0-0-2-0-2-0-0 |
| 7 | `IndTraslado` | Solo Guías de Despacho. Ver tabla 4.1.b | NUM | 1 | | P | 0-0-1-0-0-0-0-0-0-0 |
| 8 | `TpoImpresion` | Modalidad de impresión: `N` (Normal) o `T` (Ticket). Por omisión `N` | ALFA | 1 | | N | 0-0-2-0-0-0-0-0-0-0 |
| 9 | `IndServicio` | Indica prestación de servicio. Ver tabla 4.1.c | NUM | 1 | | N | 2-2-0-2-2-2-2-2-2-2 |
| 10 | `MntBruto` | Valor `1`: los montos de líneas de detalle, descuentos y recargos vienen en **montos brutos** (solo documentos sin impuestos adicionales) | NUM | 1 | | N | 2-2-0-2-2-2-2-0-0-0 |
| 11 | `TpoTranCompra` | Sugerencia de tipo de transacción de compra para el comprador (no vinculante). Ver tabla 4.1.d | NUM | 1 | | N | 3-3-3-0-0-3-3-0-0-0 |
| 12 | `TpoTranVenta` | Tipo de transacción de venta para el vendedor. Opcional en schema pero obligatorio en su uso; si no se informa se asume "Ventas del Giro". Ver tabla 4.1.e | NUM | 1 | | N | 3-3-3-3-0-3-3-0-0-0 |
| 13 | `FmaPago` | Forma de pago: `1` Contado, `2` Crédito, `3` Sin costo (entrega gratuita). **Obligatorio informar** en facturas (33), facturas exentas (34) y liquidaciones-factura (43); si no viene, se asume valor `2` (crédito) | NUM | 1 | | P | 2-2-3-2-2-2-2-3-3-3 |
| 14 | `FmaPagExp` | Forma de pago exportación: código de la Tabla de Formas de Pago de **Aduanas** (acreditivo, cobranza, anticipo, contado…), la indicada en el DUS. Para "muestras sin carácter comercial" indicar Cod. 21 | NUM | 2 | | P | 0-0-3-0-0-0-0-3-3-3 |
| 15 | `FchCancel` | Fecha de cancelación si la factura fue cancelada antes de la emisión (`AAAA-MM-DD`). Obligatorio en Factura de Exportación si `FmaPagExp` = anticipo | ALFA | 10 | | N | 3-3-3-3-3-3-3-2-3-3 |
| 16 | `MntCancel` | Monto cancelado al momento de emitir. Sin validación | NUM | 18 | | I | 3-3-3-3-3-3-3-3-3-3 |
| 17 | `SaldoInsol` | Saldo insoluto al momento de emitir. Sin validación | NUM | 18 | | I | 3-3-3-3-3-3-3-3-3-3 |
| — | `MntPagos` (tabla) | Programación de pagos del documento. **Hasta 30 repeticiones** de los 3 campos siguientes | — | — | | I | 3-3-3-3-3-3-3-3-3-3 |
| 18 | `FchPago` | Fecha de pago programado. Fecha válida | ALFA | 10 | | N | 1 dentro de la tabla |
| 19 | `MntPago` | Monto de pago programado | NUM | 18 | | N | 1 dentro de la tabla |
| 20 | `GlosaPagos` | Glosa adicional para calificar el pago | ALFA | 40 | | N | 3-3-3-3-3-3-3-2-3-3 |
| 21 | `PeriodoDesde` | Período de facturación para servicios periódicos, fecha inicial. Debe ser ≤ `PeriodoHasta` | ALFA | 10 | | N | 3-3-0-3-3-3-3-3-3-3 |
| 22 | `PeriodoHasta` | Fecha final del servicio facturado. Debe ser > `PeriodoDesde` | ALFA | 10 | | N | 3-3-0-3-3-3-3-3-3-3 |
| 23 | `MedioPago` | Medio de pago. Ver tabla 4.1.f | ALFA | 2 | | P | 3-3-0-3-3-3-3-3-3-3 |
| 24 | `TipoCtaPago` | Tipo de cuenta de pago: `CT` Cta. Cte., `AH` Ahorro, `OT` Otra | ALFA | 2 | | P | 3-3-0-3-3-3-3-3-3-3 |
| 25 | `NumCtaPago` | Número de la cuenta. Sin validación | ALFA | 20 | | P | 3-3-0-3-3-3-3-3-3-3 |
| 26 | `BcoPago` | Banco de la cuenta. Sin validación | ALFA | 40 | | P | 3-3-0-3-3-3-3-3-3-3 |
| 27 | `TermPagoCdg` | Términos del pago — código acordado entre las empresas (ej: `FRF` fecha recepción factura, `FEM` fecha entrega mercaderías). Sin validación | ALFA | 4 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 28 | `TermPagoGlosa` | Glosa de condiciones de pago. En documentos de exportación es **obligatorio si se indicó** `TermPagoCdg` | ALFA | 100 | | I | 3-3-3-3-3-3-3-2-2-2 |
| 29 | `TermPagoDias` | Cantidad de días según código de términos de pago. Número > 0 | NUM | 3 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 30 | `FchVenc` | Fecha de vencimiento del pago (`AAAA-MM-DD`), entre 2002-08-01 y 2050-12-31 | ALFA | 10 | | I | 2-2-0-3-3-3-3-2-3-3 |
| 31 | `TipoFactEsp` | Factura electrónica (33) con formato especial. Valores posibles 1–9; **Factura Turista = 1**. Ver reglas en 4.1.g | NUM | 1 | | I | 3-0-0-3-0-0-0-0-0-0 |

#### 4.1.a `TipoDespacho` — Tipos de despacho

| Valor | Significado |
|---|---|
| 1 | Despacho por cuenta del receptor del documento (cliente o vendedor en caso de Facturas de Compra) |
| 2 | Despacho por cuenta del emisor a instalaciones del cliente |
| 3 | Despacho por cuenta del emisor a otras instalaciones (ej: entrega en Obra) |

#### 4.1.b `IndTraslado` — Indicador tipo de traslado de bienes (Guías de Despacho)

| Valor | Significado |
|---|---|
| 1 | Operación constituye venta (según definición de "venta" del Art. 2° DL 825) |
| 2 | Ventas por efectuar |
| 3 | Consignaciones |
| 4 | Entrega gratuita |
| 5 | Traslados internos |
| 6 | Otros traslados no venta |
| 7 | Guía de devolución (incl. devolución de mercaderías trasladadas para exportación desde zona de embarque) |
| 8 | Traslado para exportación (no venta) — mercadería hacia puerto/aeropuerto/aduana de embarque |
| 9 | Venta para exportación — entre otros, venta de mercaderías entregadas en Zona Primaria de Aduanas para exportación |

#### 4.1.c `IndServicio` — Indicador de servicio

| Valor | Significado |
|---|---|
| 1 | Factura de servicios periódicos domiciliarios (DL 825 Art. 9°: impuesto se devenga a la fecha de vencimiento) |
| 2 | Factura de otros servicios periódicos |
| 3 | Factura de Servicios (en Factura de Exportación: servicios calificados como tal por Aduana) |
| 4 | Servicios de Hotelería (**solo Facturas de Exportación**) |
| 5 | Servicio de Transporte Terrestre Internacional (**solo Facturas de Exportación**) |

#### 4.1.d `TpoTranCompra` — Sugerencia tipo de transacción de compra

| Valor | Significado |
|---|---|
| 1 | Compras del Giro |
| 2 | Compras en Supermercados o similares |
| 3 | Adquisición Bien Raíz |
| 4 | Compra Activo Fijo |
| 5 | Compra con IVA Uso Común |
| 6 | Compra sin derecho a Crédito |
| 7 | Compra que no corresponde incluir |

#### 4.1.e `TpoTranVenta` — Tipo de transacción de venta

| Valor | Significado |
|---|---|
| 1 | Ventas del Giro (valor asumido si no se informa) |
| 2 | Venta Activo Fijo |
| 3 | Venta Bien Raíz |

#### 4.1.f `MedioPago` — Medios de pago

| Valor | Significado |
|---|---|
| `CH` | Cheque |
| `CF` | Cheque a fecha |
| `LT` | Letra |
| `EF` | Efectivo |
| `PE` | Pago a Cta. Cte. |
| `TC` | Tarjeta de Crédito |
| `OT` | Otro |

#### 4.1.g Reglas de la Factura Especial Turista (`TipoFactEsp` = 1)

- `RUTRecep` debe ser `55555555-5`.
- `CmnaOrigen` debe ser Arica, Camarones, Putre o General Lagos.
- Se activan y son obligatorios `TipoDocID` (1: Pasaporte, 2: DNI) y `NumId` del turista.
- La Razón Social del Receptor debe indicar "Extranjero sin RUT".
- Para facturación normal, `TipoFactEsp` **no debe informarse**.

### 4.2 Emisor — `<Emisor>` (área obligatoria en todos los documentos)

| # | Campo / Tag | Descripción | Tipo | Largo | (*) | I | Obligatoriedad |
|---|---|---|---|---|---|---|---|
| 32 | `RUTEmisor` | RUT del emisor con guión y DV | ALFA | 10 | * | I | 1-1-1-1-1-1-1-1-1-1 |
| 33 | `RznSoc` | Nombre o razón social del emisor | ALFA | 100 | | I | 1-1-1-1-1-1-1-1-1-1 |
| 34 | `GiroEmis` | Giro del emisor. Basta registrar el giro que corresponde a la transacción (puede ir preimpreso con todos los giros) | ALFA | 80 | | I | 1-1-1-1-1-1-1-1-1-1 |
| 35 | `Telefono` | Teléfono emisor. **Hasta 2 repeticiones** | ALFA | 20 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 36 | `CorreoEmisor` | Correo del emisor | ALFA | 80 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 37 | `Acteco` | Código(s) de actividad económica del emisor registrados en el SII. **Máximo 4**; se puede incluir solo el que corresponde a la transacción | NUM | 6 | | N | 1-1-1-1-1-1-1-1-1-1 |
| 38 | `CdgTraslado` | Código emisor traslado excepcional (solo Guías). Obligatorio si `IndTraslado` = 8 o 9. Ver tabla 4.2.a | NUM | 1 | | P | 0-0-2-0-0-0-0-0-0-0 |
| 39 | `FolioAut` | N° de Resolución del SII que autoriza al contribuyente a emitir guías en casos especiales. Obligatorio cuando `CdgTraslado` = 4 | NUM | 5 | | I | 0-0-2-0-0-0-0-0-0-0 |
| 40 | `FchAut` | Fecha de la resolución de autorización (`AAAA-MM-DD`). Obligatorio cuando `CdgTraslado` = 4 | ALFA | 10 | | I | 0-0-2-0-0-0-0-0-0-0 |
| 41 | `Sucursal` | Nombre de la sucursal que emite (dato administrado por el emisor) | ALFA | 20 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 42 | `CdgSIISucur` | Código de sucursal **entregado por el SII**. Debe corresponder a un código registrado en el SII; si no hay sucursales se omite | NUM | 9 | | N | 2-2-2-2-2-2-2-2-2-2 |
| 43 | `CodAdicSucur` | Código de identificación adicional de sucursal, uso libre (exportación) | ALFA | 20 | | N | 0-0-0-0-0-0-0-3-3-3 |
| 44 | `DirOrigen` | Dirección desde donde se despachan bienes, o de la sucursal emisora si no hay despacho | ALFA | 60 | | I | 1-1-1-3-3-1-1-1-3-3 |
| 45 | `CmnaOrigen` | Comuna de origen. Con `TipoFactEsp`=1 debe ser Arica/Camarones/Putre/General Lagos | ALFA | 20 | | I | 1-1-1-3-3-3-3-3-3-3 |
| 46 | `CiudadOrigen` | Ciudad de origen | ALFA | 20 | | N | 3-3-3-3-3-3-3-1-3-3 |
| 47 | `CdgVendedor` | Glosa identificadora del vendedor | ALFA | 60 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 48 | `IdAdicEmisor` | Identificador adicional del emisor, uso libre (documentos de exportación y guías) | ALFA | 20 | | N | 0-0-3-0-0-0-0-3-3-3 |
| 49 | `RUTMandante` | RUT del mandante si la venta/servicio es por cuenta de otro, responsable del IVA devengado. Con guión y DV | ALFA | 10 | | I | 2-2-2-2-2-0-0-0-0-0 |

*(El campo `RUTMandante` aparece en el PDF a continuación del área Emisor, fuera del tag `<Emisor>`.)*

#### 4.2.a `CdgTraslado` — Código emisor traslado excepcional (Guías)

| Valor | Significado |
|---|---|
| 1 | Exportador |
| 2 | Agente de Aduana (en devolución de mercaderías de Aduanas) |
| 3 | Vendedor (entre otros, productor que vende con entrega en Zona Primaria) |
| 4 | Contribuyente autorizado expresamente por el SII |

### 4.3 Receptor — `<Receptor>` (área obligatoria en todos los documentos)

| # | Campo / Tag | Descripción | Tipo | Largo | (*) | I | Obligatoriedad |
|---|---|---|---|---|---|---|---|
| 50 | `RUTRecep` | RUT del cliente (en Factura de Compra, RUT del vendedor). Con guión y DV. En documentos de **exportación**: `55555555-5`. En Factura Turista (`TipoFactEsp`=1): `55555555-5` | ALFA | 10 | * | I | 1-1-1-1-1-1-1-1-1-1 |
| 51 | `CdgIntRecep` | Identificación interna del receptor (código de cliente, N° de medidor, etc.) | ALFA | 20 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 52 | `RznSocRecep` | Nombre o razón social del receptor | ALFA | 100 | | I | 1-1-1-1-1-1-1-1-1-1 |
| 53 | `NumId` | Número/código de identificación del receptor extranjero (administración tributaria u organismo extranjero), con guiones y DV. **Obligatorio cuando `TipoFactEsp`=1** | ALFA | 20 | | I | 3-0-0-3-0-0-0-0-0-0 |
| 54 | `Nacionalidad` | Nacionalidad del receptor extranjero, según tabla de países de Aduana (`www.aduana.cl`) | ALFA | 3 | | N | 3-3-3-3-3-3-0-3-3-3 |
| 55 | `TipoDocID` | Documento que identifica al turista: `1` Pasaporte, `2` DNI. **Obligatorio cuando `TipoFactEsp`=1** | ALFA | 20 | | I | 3-0-0-3-0-0-0-0-0-0 |
| 56 | `IdAdicRecep` | Identificador adicional del receptor extranjero, uso libre. Solo documentos de exportación | ALFA | 20 | | N | 0-0-0-0-0-0-0-3-3-3 |
| 57 | `GiroRecep` | Giro del receptor | ALFA | 40 | | I | 1-1-1-3-3-1-1-3-3-3 |
| 58 | `Contacto` | Nombre y teléfono de contacto en empresa del receptor ("Atención a:") | ALFA | 80 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 59 | `CorreoRecep` | E-mail de contacto en empresa del receptor | ALFA | 80 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 60 | `DirRecep` | Dirección legal del receptor (registrada en el SII). En exportación: dirección en el extranjero | ALFA | 70 | | I | 1-1-1-3-3-1-1-1-3-3 |
| 61 | `CmnaRecep` | Comuna del receptor | ALFA | 20 | | I | 1-1-1-3-3-1-1-3-3-3 |
| 62 | `CiudadRecep` | Ciudad del receptor | ALFA | 20 | | N | 3-3-3-3-3-3-3-1-3-3 |
| 63 | `DirPostal` | Dirección postal del receptor | ALFA | 70 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 64 | `CmnaPostal` | Comuna postal | ALFA | 20 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 65 | `CiudadPostal` | Ciudad postal | ALFA | 20 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 66 | `RUTSolicita` | RUT de quien solicita la factura, en ventas a público. Obligatorio si es distinto del `RUTRecep` o si el receptor es persona jurídica. Con guión y DV | ALFA | 10 | | I | 2-2-0-2-2-2-0-0-0-0 |

*(`RUTSolicita` aparece en el PDF a continuación del fin del área Receptor.)*

### 4.4 Transporte — `<Transporte>` (resumen; área condicional 2-2-2-2-2-2-0-2-2-2)

Área usada cuando el documento acompaña bienes (guías, facturas con despacho) y en exportación.

| # | Campo / Tag | Descripción | Tipo | Largo | I | Obligatoriedad |
|---|---|---|---|---|---|---|
| 67 | `Patente` | Patente del vehículo. Relevante si `TipoDespacho` = 2 o 3. Puede omitirse en el XML si solo va escrita en la representación impresa que acompaña el traslado | ALFA | 8 | I | 2-2-2-0-0-2-0-3-0-0 |
| 68 | `RUTTrans` | RUT del transportista, con guión y DV. Relevante si `TipoDespacho` = 2 o 3 | ALFA | 10 | I | 2-2-2-0-0-2-0-3-0-0 |
| 69 | `RUTChofer` | RUT del chofer que realiza el transporte, con guión y DV | ALFA | 10 | I | 3-3-2-3-3-3-0-3-3-3 |
| 70 | `NombreChofer` | Nombre del chofer. Si se digita el RUT del chofer, debe indicarse el nombre | ALFA | 30 | I | 2-2-2-2-2-2-0-3-3-3 |
| 71 | `DirDest` | Dirección de destino (si distinta de Dirección Receptor, o de Dirección Emisor en Factura de Compra). En servicios periódicos, dirección donde se otorga el servicio | ALFA | 70 | I | 2-2-2-3-3-2-0-2-3-3 |
| 72 | `CmnaDest` | Comuna de destino | ALFA | 20 | I | 2-2-1-3-3-2-0-3-3-3 |
| 73 | `CiudadDest` | Ciudad de destino | ALFA | 20 | N | 3-3-3-3-3-3-0-2-3-3 |

#### Sub-área `TRANSPORTE.ADUANA` (exportación; resumen — códigos según tablas de Aduana)

Sub-área con obligatoriedad 0-0-2-0-0-0-0-2-3-3. Todos los códigos provienen de tablas
publicadas en `www.aduana.cl` (no incluidas en el PDF).

| # | Campo / Tag | Descripción | Tipo | Largo | I | Notas de obligatoriedad |
|---|---|---|---|---|---|---|
| 74 | `CodModVenta` | Modalidad de venta (a firme, en consignación, consignación con mínimo a firme, etc.), tabla "Modalidad de Venta" de Aduana | NUM | 2 | P | Obligatorio en Factura de Exportación, excepto si `IndServicio` = 3, 4 o 5. Matriz: 0-0-3-0-0-0-0-2-3-3 |
| 75 | `CodClauVenta` | Cláusula de venta del DUS (FOB, CIF, etc.), tabla "Cláusula compra-venta" de Aduana | NUM | 2 | P | Obligatorio, excepto si `IndServicio` = 3, 4 o 5. Matriz: 0-0-3-0-0-0-0-2-3-3 |
| 76 | `TotClauVenta` | Valor total de la exportación según cláusula de venta del DUS (sin comisiones ni gastos deducibles en el exterior). 18 dígitos con 2 decimales | NUM | 18 | I | Obligatorio, excepto si `IndServicio` = 3, 4 o 5. Matriz: 0-0-3-0-0-0-0-2-3-3 |
| 77 | `CodViaTransp` | Vía de transporte (aéreo, terrestre, marítimo…), tabla Vías de Transporte de Aduana | NUM | 2 | I | Obligatorio, excepto si `IndServicio` = 4. Matriz: 0-0-3-0-0-0-0-2-3-3 |
| 78 | `NombreTransp` | Nombre o glosa de la nave transportista | ALFA | 40 | I | 0-0-3-0-0-0-0-3-3-3 |
| 79 | `RUTCiaTransp` | RUT de la compañía transportista indicada en el DUS (si es extranjera, RUT de la agencia que la representa en Chile) | ALFA | 10 | I | 0-0-3-0-0-0-0-3-3-3 |
| 80 | `NomCiaTransp` | Nombre de la cía. transportadora declarada en el DUS | ALFA | 40 | I | 0-0-3-0-0-0-0-3-3-3 |
| 81 | `IdAdicTransp` | Identificación adicional cía. transportadora, uso libre | ALFA | 20 | N | 0-0-3-0-0-0-0-3-3-3 |
| 82 | `Booking` | Número de booking o reserva del operador | ALFA | 20 | N | 0-0-3-0-0-0-0-3-3-3 |
| 83 | `Operador` | Código de operador | ALFA | 20 | N | 0-0-3-0-0-0-0-3-3-3 |
| 84 | `CodPtoEmbarque` | Puerto de embarque, tabla de puertos de Aduana. En Guías: obligatorio solo si `IndTraslado` = 8 o 9. En Fact. Exportación: obligatorio excepto `IndServicio` = 4 | NUM | 4 | P | 0-0-2-0-0-0-0-3-3-3 |
| 85 | `IdAdicPtoEmb` | Identificador adicional puerto de embarque, uso libre | ALFA | 20 | N | 0-0-3-0-0-0-0-3-3-3 |
| 86 | `CodPtoDesemb` | Puerto de desembarque, tabla de Aduana. Mismas condiciones que `CodPtoEmbarque` | NUM | 4 | P | 0-0-2-0-0-0-0-3-3-3 |
| 87 | `IdAdicPtoDesemb` | Identificador adicional puerto de desembarque, uso libre | ALFA | 20 | N | 0-0-3-0-0-0-0-3-3-3 |
| 88 | `Tara` | Tara (número entero) | NUM | 7 | I | 0-0-3-0-0-0-0-3-3-3 |
| 89 | `CodUnidMedTara` | Unidad de medida de la tara, tabla "Unidades de Medida" de Aduana | NUM | 2 | P | 0-0-2-0-0-0-0-2-3-3 |
| 90 | `PesoBruto` | Sumatoria de pesos brutos de todos los ítems, con 2 decimales (10 enteros + 2 decimales). En Guías: obligatorio solo si `IndTraslado` = 8 o 9 | NUM | 12 | I | 0-0-2-0-0-0-0-3-3-3 |
| 91 | `CodUnidPesoBruto` | Unidad de medida del peso bruto, tabla de Aduana. En Guías: obligatorio solo si `IndTraslado` = 8 o 9 | NUM | 2 | P | 0-0-2-0-0-0-0-2-3-3 |
| 92 | `PesoNeto` | Sumatoria del peso neto de todos los ítems, con 2 decimales | NUM | 12 | N | 0-0-3-0-0-0-0-3-3-3 |
| 93 | `CodUnidPesoNeto` | Unidad de medida del peso neto, tabla de Aduana | NUM | 2 | P | 0-0-2-0-0-0-0-2-3-3 |
| 94 | `TotItems` | Total de ítems del documento (entero sin decimales) | NUM | 18 | N | 0-0-3-0-0-0-0-3-3-3 |
| 95 | `TotBultos` | Cantidad total de bultos que ampara el documento (entero). En Guías: obligatorio solo si `IndTraslado` = 8 o 9 | NUM | 18 | I | 0-0-2-0-0-0-0-1-3-3 |
| — | `TipoBultos` (tabla) | Descripción de tipos de bultos. **Hasta 10 repeticiones**, solo si se informó `TotBultos`. Contiene los 6 campos siguientes | — | — | — | 0-0-2-0-0-0-0-3-3-3 |
| 96 | `CodTpoBultos` | Código del tipo de bulto, tabla Tipos de Bultos de `www.aduana.cl` | NUM | 3 | I | 0-0-2-0-0-0-0-3-3-3 |
| 97 | `CantBultos` | Cantidad total de bultos de este tipo | NUM | 10 | I | 0-0-2-0-0-0-0-2-3-3 |
| 98 | `Marcas` | Identificación de marcas (cuando es distinto de contenedor) | ALFA | 255 | I | 0-0-2-0-0-0-0-2-3-3 |
| 99 | `IdContainer` | Id. del container (con guión y DV). Este campo y los dos siguientes solo si el tipo de bulto es contenedor | ALFA | 25 | I | 0-0-3-0-0-0-0-3-3-3 |
| 100 | `Sello` | Sello del contenedor, con DV | ALFA | 20 | N | 0-0-3-0-0-0-0-3-3-3 |
| 101 | `EmisorSello` | Nombre del emisor del sello | ALFA | 70 | N | 0-0-3-0-0-0-0-3-3-3 |
| 102 | `MntFlete` | Monto del flete según moneda de venta. 14 enteros + 4 decimales, **estrictamente mayor que cero** | ALFA | 18 | N | 0-0-3-0-0-0-0-3-3-3 |
| 103 | `MntSeguro` | Monto del seguro según moneda de venta. 14 enteros + 4 decimales, **estrictamente mayor que cero** | ALFA | 18 | N | 0-0-3-0-0-0-0-3-3-3 |
| 104 | `CodPaisRecep` | Código del país del receptor extranjero, tabla de países de Aduana | ALFA | 3 | P | 0-0-3-0-0-0-0-1-3-3 |
| 105 | `CodPaisDestin` | Código del país de destino de la mercadería, tabla de Aduana | ALFA | 3 | P | 0-0-3-0-0-0-0-2-3-3 |

### 4.5 Totales — `<Totales>` (área obligatoria en todos los documentos)

| # | Campo / Tag | Descripción | Tipo | Largo | (*) | I | Obligatoriedad |
|---|---|---|---|---|---|---|---|
| 106 | `TpoMoneda` | Moneda en que se registra la transacción de **exportación**; todos los montos del documento quedan en esta moneda. Valores según schema, ej: `DOLAR USA`, `EURO` | ALFA | 15 | | I | 0-0-0-0-0-0-0-1-1-1 |
| 107 | `MntNeto` | Suma de valores de ítems afectos − descuentos globales + recargos globales (asignados a ítems afectos). Si `MntBruto`=1, el resultado se divide por (1 + tasa IVA). En Liquidaciones-Factura puede ser negativo | NUM | 18 | | I | 2-0-3-2-2-2-2-0-0-0 |
| 108 | `MntExe` | Suma de valores de ítems no afectos o exentos − descuentos globales + recargos globales (asignados a ítems exentos/no afectos). En Liquidaciones-Factura puede ser negativo | NUM | 18 | | I | 2-1-3-2-2-2-2-1-1-1 |
| 109 | `MntBase` | Monto base faenamiento carne. Valores > 0 | NUM | 18 | | I | 2-0-3-2-2-0-0-0-0-0 |
| 110 | `MntMargenCom` | Monto base de márgenes de comercialización (informado) | NUM | 18 | | I | 2-0-3-2-2-0-0-0-0-0 |
| 111 | `TasaIVA` | Tasa de IVA vigente, en porcentaje. 3 enteros + 2 decimales (ej: `19`) | NUM | 5 | | I | 2-2-3-2-2-2-2-0-0-0 |
| 112 | `IVA` | Valor numérico = `MntNeto` × tasa IVA. ≥ 0 excepto en Liquidaciones-Factura (puede ser negativo) | NUM | 18 | | I | 2-2-3-2-2-2-2-0-0-0 |
| 113 | `IVAProp` | IVA propio (empresas que venden por cuenta de un mandatario pueden separar IVA en propio y de terceros; `IVA` sigue conteniendo el total). Debe ser < `IVA` | NUM | 18 | | N | 3-0-3-3-3-3-3-0-0-0 |
| 114 | `IVATerc` | IVA de terceros. Ídem anterior; < `IVA` | NUM | 18 | | N | 3-0-3-3-3-3-3-0-0-0 |
| — | `ImptoReten` (tabla) | Impuestos adicionales y retenciones. **Hasta 20 repeticiones** de los pares código–tasa–valor siguientes | — | — | | — | 2-2-3-2-2-2-2-0-0-0 |
| 115 | `TipoImp` | Código del impuesto adicional o retención, según tabla de la sección 12 (incluye retención cambio de sujeto de construcción) | ALFA | 3 | | P | 2-2-2-2-2-2-2-0-0-0 |
| 116 | `TasaImp` | Tasa del impuesto o retención (válida al momento de la transacción). En impuestos específicos se puede omitir | NUM | 5 | | I | 2-2-2-2-2-2-2-0-0-0 |
| 117 | `MontoImp` | Valor del impuesto o retención asociado al código. Validación: (a) tasa × (suma de líneas de detalle con ese código), excepto diésel, gasolina, margen de comercialización e IVA anticipado faenamiento carne; (b) tasa × monto base faenamiento para IVA anticipado faenamiento carne; (c) valor numérico > 0 en otros casos | NUM | 18 | | I | 2-2-2-2-2-2-2-0-0-0 |
| 118 | `IVANoRet` | IVA no retenido: solo Facturas de Compra con retención de IVA por el emisor, y NC/ND que las referencian. = IVA − IVA retenido por producto. No se registra si es 0 | NUM | 18 | | I | 0-0-0-2-2-2-0-0-0-0 |
| 119 | `CredEC` | Crédito especial 65% empresas constructoras (Art. 21 DL 910/75). Valor = `IVA` × 0,65. Es el único monto que **se resta** al IVA general. No aplica a Factura de Compra | NUM | 18 | | I | 2-0-3-2-2-0-0-0-0-0 |
| 120 | `GrntDep` | Garantía por depósito de envases o embalajes (no afecto), empresas que usan envases habitualmente por su giro (Art. 28 inc. 3 Regl. DL 825). Sumatoria de líneas de detalle con `IndExe` = 3 | NUM | 18 | | I | 2-2-0-2-2-0-0-0-0-0 |
| 121 | `ValComNeto` | Valor neto comisiones y otros cargos (suma del detalle de la zona F). En Liquidaciones-Factura puede ser negativo | NUM | 18 | | I | 0-0-0-2-2-2-2-0-0-0 |
| 122 | `ValComExe` | Valor comisiones y otros cargos no afectos o exentos. En Liquidaciones-Factura puede ser negativo | NUM | 18 | | I | 0-0-0-2-2-2-2-0-0-0 |
| 123 | `ValComIVA` | IVA de comisiones y otros cargos. En Liquidaciones-Factura puede ser negativo | NUM | 18 | | N | 0-0-0-2-2-2-2-0-0-0 |
| 124 | `MntTotal` | **Monto total**. Fórmula en 4.5.a. En Liquidaciones-Factura puede ser negativo. En documentos de exportación es `0` si `FmaPagExp` = 21 (sin pago) | NUM | 18 | * | I | 1-1-1-1-1-1-1-1-1-1 |
| 125 | `MontoNF` | Monto no facturable: suma de ítems con `IndExe`=2 menos suma de ítems con `IndExe`=6. Puede ser negativo | NUM | 18 | | N | 2-2-2-2-2-2-0-0-0-0 |
| 126 | `MontoPeriodo` | `MntTotal` + `MontoNF`. Puede ser negativo | NUM | 18 | | N | 3-3-3-3-3-3-3-0-0-0 |
| 127 | `SaldoAnterior` | Saldo anterior, solo para ilustrar el cobro. Puede ser negativo | NUM | 18 | | N | 3-3-3-3-3-3-3-0-0-0 |
| 128 | `VlrPagar` | Valor cobrado. Sin validación; puede ser negativo o cero | NUM | 18 | | N | 3-3-3-3-3-3-3-0-0-0 |

#### 4.5.a Fórmula de `MntTotal`

```
MntTotal = MntNeto
         + MntExe                       (monto no afecto o exento)
         + IVA
         + Impuestos Adicionales        (tabla ImptoReten)
         + Impuestos Específicos
         + IVA Margen Comercialización
         + IVA Anticipado
         + GrntDep                      (garantía por depósito de envases)
         - CredEC                       (crédito empresas constructoras)
         - IVA Retenido productos       (en Facturas de Compra)
         - ValComNeto - ValComIVA - ValComExe   (comisiones y otros cargos)
```

(Los impuestos adicionales y el IVA anticipado van detallados en la tabla `ImptoReten`.)

### 4.6 Otra Moneda del encabezado — `<OtraMoneda>` (área opcional, 3 en todos)

Montos totales expresados en una moneda alternativa. **En documentos de exportación es
obligatorio informar aquí la conversión a pesos chilenos** (`TpoMoneda` = `PESO CL`), con
`TpoCambio`, `MntExeOtrMnda` y `MntTotOtrMnda` en pesos chilenos (cambio normativo 31/05/2017).

| # | Campo / Tag | Descripción | Tipo | Largo | I | Obligatoriedad |
|---|---|---|---|---|---|---|
| 129 | `TpoMoneda` | Moneda alternativa de los montos totales (valores del schema: `DOLAR USA`, `EURO`, `PESO CL`, etc.). En exportación: obligatorio con `PESO CL` | ALFA | 15 | P | 2-2-2-2-2-2-2-2-2-2 |
| 130 | `TpoCambio` | Factor de conversión de pesos a otra moneda: 6 enteros + 4 decimales. En exportación: tipo de cambio a la fecha de emisión publicado por el Banco Central de Chile; obligatorio para convertir a pesos chilenos | NUM | 10 | N | 3-3-2-3-3-3-3-3-3-3 |
| 131 | `MntNetoOtrMnda` | Monto neto en otra moneda (misma lógica de `MntNeto`; con `MntBruto`=1 dividir por 1+tasa). 14 enteros + 4 decimales. Sin validación de fórmula | NUM | 18 | I | 3-0-3-3-3-3-0-0-0-0 |
| 132 | `MntExeOtrMnda` | Monto no afecto o exento en otra moneda. 14 enteros + 4 decimales. **Obligatorio en exportación (en pesos chilenos)** | NUM | 18 | I | 3-3-3-3-3-3-0-3-3-3 |
| 133 | `MntFaeCarneOtrMnda` | Monto base faenamiento carne en otra moneda. 14 enteros + 4 decimales, > 0 | NUM | 18 | I | 3-0-3-3-3-0-0-0-0-0 |
| 134 | `MntMargComOtrMnda` | Monto base márgenes de comercialización en otra moneda | NUM | 18 | I | 2-0-3-2-2-0-0-0-0-0 |
| 135 | `IVAOtrMnda` | IVA en otra moneda = monto neto en otra moneda × tasa IVA. 14 enteros + 4 decimales; ≥ 0 excepto Liquidaciones-Factura | NUM | 18 | I | 2-2-3-2-2-2-2-0-0-0 |
| — | `ImpRetOtrMnda` (tabla) | Impuestos adicionales y retenciones en otra moneda. Hasta 20 repeticiones de: `TipoImpOtrMnda` (ALFA 3), `TasaImpOtrMnda` (NUM 5), `VlrImpOtrMnda` (NUM 18). Mismas reglas que la tabla `ImptoReten` | — | — | — | 2-2-3-2-2-2-2-0-0-0 |
| 137 | `IVANoRetOtrMnda` | IVA no retenido en otra moneda (solo FC y NC/ND que referencian FC). 14 enteros + 4 decimales; no se registra si es 0 | NUM | 18 | I | 0-0-0-3-3-3-0-0-0-0 |
| 138 | `MntTotOtrMnda` | Monto total en otra moneda (misma fórmula de `MntTotal` en la otra moneda). 14 enteros + 4 decimales. **Obligatorio en exportación (en pesos chilenos)**. En Liquidaciones-Factura puede ser negativo | NUM | 18 | I | 2-2-2-2-2-2-2-2-2-2 |

---

## 5. B — DETALLE DE PRODUCTOS O SERVICIOS — `<Detalle>`

- Debe ir **al menos una línea** de detalle; **máximo 60 ítems** (y solo la cantidad imprimible
  en una hoja según normativa de impresión del SII).

| # | Campo / Tag | Descripción | Tipo | Largo | (*) | I | Obligatoriedad |
|---|---|---|---|---|---|---|---|
| 1 | `NroLinDet` | Número secuencial del ítem, de 1 a 60 | NUM | 4 | * | N | 1-1-1-1-1-1-1-1-1-1 |
| — | `CdgItem` (tabla) | Códigos del ítem. **Hasta 5 repeticiones** de pares tipo–código | — | — | | — | opcional |
| 2 | `TpoCodigo` | Tipo de codificación del ítem. Estándar: EAN, PLU, DUN o interna. Ej: `EAN13`, `PLU`, `DUN14`, `INT1`, `INT2`, `EAN128` | ALFA | 10 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 3 | `VlrCodigo` | Código del producto según el tipo de codificación anterior | ALFA | 35 | | N | 3-3-3-3-3-3-3-3-3-3 |
| 4 | `TpoDocLiq` | Solo Liquidaciones: código del documento que se liquida (ej: 30, 33, 35, 39, 56…), electrónico o manual; o `99` para anticipos u otras transacciones | ALFA | 3 | | N | 0-0-0-0-0-0-1-0-0-0 |
| 5 | `IndExe` | Indicador de facturación/exención del ítem. Ver tabla 5.a | NUM | 1 | | N | 2-2-3-2-2-2-2-2-2-2 |
| — | `<Retenedor>` (área) | Solo agentes retenedores. Campos 6–9 | — | — | | — | condicional |
| 6 | `IndAgente` | Indicador agente retenedor: valor `R`. Obligatorio para agentes retenedores, por transacción/producto | ALFA | 1 | | N | 2-0-3-2-2-2-0-0-0-0 |
| 7 | `MntBaseFaena` | Monto base faenamiento. Solo transacciones de agentes retenedores, código de retención 17 | NUM | 18 | | I | 2-0-3-2-2-2-0-0-0-0 |
| 8 | `MntMargComer` | Monto base márgenes de comercialización. Solo agentes retenedores, códigos de retención 14 y 50 | NUM | 18 | | I | 2-0-3-2-2-2-0-0-0-0 |
| 9 | `PrcConsFinal` | Precio unitario neto consumidor final. Solo agentes retenedores, códigos 14, 17 y 50 | NUM | 18 | | I | 2-0-3-2-2-0-0-0-0-0 |
| 10 | `NmbItem` | Nombre del producto o servicio | ALFA | 80 | * | I | 1-1-1-1-1-1-1-1-1-1 |
| 11 | `DscItem` | Descripción adicional (packs, servicios con detalle) | ALFA | 1000 | | I | 3-3-3-3-3-3-3-3-3-3 |
| 12 | `QtyRef` | Cantidad para la unidad de medida de referencia (no se usa para calcular el valor neto). 12 enteros + 6 decimales. Obligatorio para facturas de venta o compra de emisor agente retenedor. En Guías con `IndTraslado` 8/9: obligatoria si `QtyItem` no está en kgs brutos | NUM | 18 | | N | 2-3-2-2-2-2-3-3-3-3 |
| 13 | `UnmdRef` | Glosa unidad de medida de referencia. Obligatorio para facturas de venta, compra o notas de emisor agente retenedor. En Guías con `IndTraslado` 8/9: obligatoria si `QtyItem` no está en kgs brutos (usar tabla de unidades de Aduana) | ALFA | 4 | | N | 2-3-2-2-2-2-3-3-3-3 |
| 14 | `PrcRef` | Precio unitario para la unidad de referencia (no se usa para el valor neto). 12 enteros + 6 decimales. Obligatorio para agentes retenedores | NUM | 18 | | N | 2-3-3-2-2-2-3-3-3-3 |
| 15 | `QtyItem` | Cantidad del ítem. 12 enteros + 6 decimales. Obligatorio para agentes retenedores. En Facturas de Exportación: obligatorio excepto `IndServicio` = 3, 4 o 5 | NUM | 18 | | I | 2-3-1-2-2-2-3-2-2-2 |
| — | `Subcantidad` (tabla) | Distribución de la cantidad. **Hasta 5 repeticiones** de pares cantidad–código | — | — | | N | 3-3-3-3-3-3-3-3-3-3 |
| 16 | `SubQty` | Subcantidad distribuida. 12 enteros + 6 decimales; ≤ `QtyItem` | NUM | 18 | | N | 3-3-3-0-0-3-3-3-3-3 |
| 17 | `SubCod` | Código descriptivo de la subcantidad (hasta 5 veces) | ALFA | 35 | | N | 3-3-3-0-0-3-3-3-3-3 |
| 18 | `TipCodSubQty` | Tipo de código de subcantidad. Solo documentos de exportación | ALFA | 10 | | — | 0-0-0-0-0-0-0-3-3-3 |
| 19 | `FchElabor` | Fecha de elaboración del ítem (fecha válida) | ALFA | 10 | | N | 3-3-3-0-0-3-3-3-3-3 |
| 20 | `FchVencim` | Fecha de vencimiento del ítem (fecha válida) | ALFA | 10 | | N | 3-3-3-0-0-3-3-3-3-3 |
| 21 | `UnmdItem` | Unidad de medida. Obligatorio para facturas de venta/compra o notas de emisor agente retenedor; obligatorio en Guías con `IndTraslado` 8/9; en Facturas de Exportación obligatorio excepto `IndServicio` = 3, 4 o 5 (en ese caso usar tabla de unidades de Aduana) | ALFA | 4 | | I | 2-3-2-2-2-2-3-2-2-2 |
| 22 | `PrcItem` | Precio unitario del ítem. 12 enteros + 6 decimales | NUM | 18 | | I | 2-2-2-2-2-2-3-3-3-3 |
| — | `OtrMnda` (tabla) | Otra moneda del detalle. **Hasta 2 repeticiones** para precios en monedas alternativas (campos 23–28) | — | — | | — | 3-3-3-3-3-3-0-3-3-3 |
| 23 | `PrcOtrMon` | Precio unitario en otra moneda. 14 enteros + 4 decimales. Obligatorio en Guías con `IndTraslado` = 9 | NUM | 18 | | N | 2-2-2-2-2-2-0-2-2-2 |
| 24 | `Moneda` | Moneda del precio anterior, según tabla del Banco Central. En Guía de Despacho debe indicarse si se informa `PrcOtrMon` | ALFA | 3 | | N | 2-2-2-2-2-2-0-2-2-2 |
| 25 | `FctConv` | Factor de conversión a pesos: 6 enteros + 4 decimales. En exportación: tipo de cambio de la fecha de emisión publicado por el Banco Central | NUM | 10 | | N | 2-2-2-2-2-2-0-2-2-2 |
| 26 | `DctoOtrMnda` | Descuento (dinero) del ítem en otra moneda. 14 enteros + 4 decimales | NUM | 18 | | N | 3-3-3-3-3-3-0-3-3-3 |
| 27 | `RecargoOtrMnda` | Recargo (dinero) del ítem en otra moneda. 14 enteros + 4 decimales | NUM | 18 | | N | 3-3-3-3-3-3-0-3-3-3 |
| 28 | `MontoItemOtrMnda` | Valor por línea en otra moneda = (`PrcOtrMon` × cantidad) − `DctoOtrMnda` + `RecargoOtrMnda`. 14 enteros + 4 decimales. Obligatorio en Guías con `IndTraslado` = 9 | NUM | 18 | | I | 2-2-2-2-2-2-0-2-2-2 |
| 29 | `DescuentoPct` | Descuento en %: 3 enteros + 2 decimales | NUM | 5 | | N | 3-3-3-3-3-3-0-3-3-3 |
| 30 | `DescuentoMonto` | Monto del descuento (totaliza todos los descuentos del ítem). Si va el descuento en %, debe ir el monto correspondiente | NUM | 18 | | I | 2-2-3-2-2-2-0-3-3-3 |
| — | `SubDscto` (tabla) | Distribución del descuento. **Hasta 5 repeticiones** de pares tipo–valor | — | — | | N | 3-3-3-3-3-3-0-3-3-3 |
| 31 | `TipoDscto` | Tipo de sub-descuento: `$` o `%` | ALFA | 1 | | N | 3-3-3-3-3-3-0-3-3-3 |
| 32 | `ValorDscto` | Valor del sub-descuento: 16 enteros + 2 decimales | NUM | 18 | | N | 3-3-3-3-3-3-0-3-3-3 |
| 33 | `RecargoPct` | Recargo en %: 3 enteros + 2 decimales | NUM | 5 | | N | 2-2-3-3-3-2-0-3-3-3 |
| 34 | `RecargoMonto` | Monto del recargo (totaliza todos los recargos del ítem). Si va el recargo en %, debe ir el monto | NUM | 18 | | I | 2-2-3-2-2-2-0-3-3-3 |
| — | `SubRecargo` (tabla) | Distribución del recargo. **Hasta 5 repeticiones**: `TipoRecargo` (ALFA 1, `$` o `%`) y `ValorRecargo` (NUM 18, 16 enteros + 2 decimales) | — | — | | N | 3-3-3-3-3-3-0-3-3-3 |
| 37 | `CodImpAdic` | Código de impuesto adicional o retención del ítem, según tabla de la sección 12. **Hasta 2 repeticiones** por línea | ALFA | 6 | | N | 2-2-3-2-2-2-0-0-0-0 |
| 38 | `MontoItem` | Valor por línea de detalle = (`PrcItem` × `QtyItem`) − `DescuentoMonto` + `RecargoMonto`. Ver reglas en 5.b | NUM | 18 | * | I | 1-1-1-1-1-1-1-1-1-1 |

#### 5.a `IndExe` — Indicador de facturación / exención del ítem

| Valor | Significado |
|---|---|
| 1 | Producto o servicio **no afecto o exento de IVA**. *No se usa si la factura es exenta en forma global.* |
| 2 | Producto o servicio **no facturable** |
| 3 | **Garantía de depósito por envases** (cervezas, jugos, aguas minerales, bebidas analcohólicas u otros autorizados por resolución especial; Art. 28 inc. 3 Regl. DL 825) |
| 4 | **Ítem no venta** (para facturas y guías de despacho — esta última con `IndTraslado` = 1 — cuando el ítem no será facturado) |
| 5 | **Ítem a rebajar**: para guías de despacho NO VENTA que rebajan una guía anterior (la guía anterior se indica en Referencias) |
| 6 | Producto o servicio **no facturable negativo** (excepto en liquidaciones-factura) |

Reglas asociadas:

- Si **todos** los ítems tienen `IndExe` = 1, el documento no puede ser Factura Electrónica
  (33); debería ser Factura No Afecta o Exenta (34).
- Solo en Liquidación-Factura con ítems no facturables **negativos**: se usa `IndExe` = 2 y el
  valor se informa con signo negativo.

#### 5.b Reglas de `MontoItem`

1. **Debe ser cero** cuando: `IndExe` = 4 o 5, o el documento es una Nota de Crédito tipo
   "fe de erratas" (ver `CodRef` = 2 en Referencias).
2. **Puede ser cero** cuando el documento es una Guía de Despacho NO VENTA (según
   `IndTraslado`).
3. En Liquidaciones-Factura **puede ser negativo**.
4. Cuando es cero, puede no imprimirse o imprimirse un texto explicativo ("s/valor",
   "sin costo", etc.).
5. Si la factura es exenta (o el ítem tiene `IndExe` = 1), este valor se entiende como valor
   **exento** por línea; en el resto de los casos, como valor **neto** por línea.

---

## 6. C — SUBTOTALES INFORMATIVOS — `<SubTotInfo>`

De 0 a **20 líneas**. **No** aumentan ni disminuyen la base del impuesto ni modifican los
totalizadores: son solo informativos (p. ej. subtotal de un grupo de productos). En la
representación impresa pueden intercalarse entre las líneas de detalle o agruparse aparte.

| # | Campo / Tag | Descripción | Tipo | Largo | I | Obligatoriedad |
|---|---|---|---|---|---|---|
| 1 | `NroSTI` | Número secuencial del subtotal | NUM | 2 | N | 1 en todos (si existe la zona) |
| 2 | `GlosaSTI` | Título/concepto del subtotal | ALFA | 40 | N | 1 en todos (si existe la zona) |
| 3 | `OrdenSTI` | Ubicación para impresión (ayuda del contribuyente) | NUM | 2 | N | 3 en todos |
| 4 | `SubTotNetoSTI` | Valor neto del subtotal. 16 enteros + 2 decimales, sin validación | NUM | 18 | N | 3 (0 en documentos de exportación) |
| 5 | `SubTotIVASTI` | Valor del IVA del subtotal. 16 enteros + 2 decimales, sin validación | NUM | 18 | N | 3 (0 en documentos de exportación) |
| 6 | `SubTotAdicSTI` | Valor de impuestos adicionales o específicos del subtotal | NUM | 18 | N | 3 (0 en documentos de exportación) |
| 7 | `SubTotExeSTI` | Valor no afecto o exento del subtotal | NUM | 18 | N | 3 en todos |
| 8 | `ValSubtotSTI` | Valor de la línea de subtotal | NUM | 18 | N | 3 en todos |
| 9 | `LineasDeta` | Números de línea de detalle que agrupa. **Hasta 60 repeticiones** | NUM | 2 | N | 3 en todos |

---

## 7. D — DESCUENTOS Y RECARGOS GLOBALES — `<DscRcgGlobal>`

De 0 a **20 líneas**. **Sí** aumentan o disminuyen la base del impuesto. Llevan glosa que
especifica el concepto (p. ej. descuento por pago contado).

Reglas cuando se aplican descuentos/recargos globales:

- a) Si en Detalle hay ítems con **distintos códigos de impuesto o retención**, el campo
  `TpoValor` del descuento **debe ser `%`**.
- b) Si en Detalle hay ítems afectos, exentos y no facturables (`IndExe` = 1 o 2):
  - Si el descuento afecta solo a los ítems **exentos**: indicar `IndExeDR` = 1.
  - Si afecta solo a los ítems **afectos**: **no** llevar `IndExeDR`.
  - Si afecta solo a los **no facturables**: indicar `IndExeDR` = 2.
  - Si afecta a **todos**: deben ir **tres líneas** (una para afectos, otra para exentos y
    otra para no facturables).

| # | Campo / Tag | Descripción | Tipo | Largo | I | Obligatoriedad |
|---|---|---|---|---|---|---|
| 1 | `NroLinDR` | Número secuencial del descuento/recargo, de 1 a 20 (si se incluye la zona debe haber al menos una línea) | NUM | 2 | N | 1-1-1-1-1-1-0-1-1-1 |
| 2 | `TpoMov` | Tipo de movimiento: `D` (descuento) o `R` (recargo) | ALFA | 1 | N | 1-1-1-1-1-1-0-1-1-1 |
| 3 | `GlosaDR` | Especificación del descuento o recargo | ALFA | 45 | I | 3-3-3-3-3-3-0-3-3-3 |
| 4 | `TpoValor` | `%` (porcentaje) o `$` (monto) | ALFA | 1 | I | 1-1-1-1-1-1-0-1-1-1 |
| 5 | `ValorDR` | Valor del descuento o recargo: 16 enteros + 2 decimales (monto si `TpoValor`=`$`, porcentaje en otro caso) | NUM | 18 | I | 1-1-1-1-1-1-0-3-3-3 |
| 6 | `ValorDROtrMnda` | Valor en otra moneda: 14 enteros + 4 decimales | NUM | 18 | I | 3-3-3-3-3-3-0-1-1-1 |
| 7 | `IndExeDR` | Indicador de facturación/exención del D/R: `1` no afecto o exento de IVA, `2` no facturable | NUM | 1 | N | 2-2-2-2-2-2-0-2-2-2 |

---

## 8. E — INFORMACIÓN DE REFERENCIA — `<Referencia>`

De 0 a **40 repeticiones**.

| # | Campo / Tag | Descripción | Tipo | Largo | I | Obligatoriedad |
|---|---|---|---|---|---|---|
| 1 | `NroLinRef` | Número secuencial de la referencia, de 1 a 40 | NUM | 2 | N | 1-1-1-1-1-1-1-1-1-1 |
| 2 | `TpoDocRef` | Tipo de documento de referencia. Ver tabla 8.a y reglas 8.b | ALFA | 3 | I | 1-1-1-1-1-1-1-1-1-1 |
| 3 | `IndGlobal` | Indicador de referencia global. Valor `1`: el documento afecta a **más de 20 documentos** del mismo `TpoDocRef` (ej: factura de todas las guías del mes). La razón se explicita en `RazonRef` | NUM | 1 | — | 2-2-2-2-2-2-2-2-2-2 |
| 4 | `FolioRef` | Folio del documento de referencia. Debe ser `0` solo si `IndGlobal` está encendido. Puede ser alfanumérico si es documento no tributario (rango 800) | ALFA | 18 | I | 1-1-1-1-1-1-1-1-1-1 |
| 5 | `RUTOtr` | RUT de otro contribuyente, con guión y DV. Solo si el documento de referencia es tributario y fue emitido por otro contribuyente. Ver 8.c | ALFA | 10 | N | 0-0-0-2-2-2-0-3-3-3 |
| 6 | `IdAdicOtr` | Identificador adicional de otro contribuyente, uso libre (exportación) | ALFA | 20 | N | 0-0-0-0-0-0-0-3-3-3 |
| 7 | `FchRef` | Fecha del documento de referencia, entre 2002-08-01 y 2050-12-31 | ALFA | 10 | I | 1-1-1-1-1-1-1-1-1-1 |
| 8 | `CodRef` | Código de referencia. Ver tabla 8.d | NUM | 1 | N | 3-3-3-1-1-3-3-3-1-1 |
| 9 | `RazonRef` | Razón de la referencia (ej: "descuento por pronto pago", "error en precio") | ALFA | 90 | N | 3-3-3-3-3-3-3-3-3-3 |

### 8.a `TpoDocRef` — Códigos de tipo de documento de referencia

Documentos tributarios (valor numérico validado):

| Código | Documento |
|---|---|
| 30 | Factura |
| 32 | Factura de venta de bienes y servicios no afectos o exentos de IVA |
| 33 | Factura Electrónica |
| 34 | Factura No Afecta o Exenta Electrónica |
| 35 | Boleta |
| 38 | Boleta exenta |
| 39 | Boleta Electrónica |
| 40 | Liquidación Factura |
| 41 | Boleta Exenta Electrónica |
| 43 | Liquidación-Factura Electrónica |
| 45 | Factura de compra |
| 46 | Factura de Compra Electrónica |
| 50 | Guía de Despacho |
| 52 | Guía de Despacho Electrónica |
| 55 | Nota de débito |
| 56 | Nota de Débito Electrónica |
| 60 | Nota de crédito |
| 61 | Nota de Crédito Electrónica |
| 103 | Liquidación |
| 110 | Factura de Exportación Electrónica |
| 111 | Nota de Débito de Exportación Electrónica |
| 112 | Nota de Crédito de Exportación Electrónica |

Documentos no tributarios (rango 800; `FolioRef` puede ser alfanumérico):

| Código | Documento |
|---|---|
| 801 | Orden de Compra |
| 802 | Nota de pedido |
| 803 | Contrato |
| 804 | Resolución |
| 805 | Proceso ChileCompra |
| 806 | Ficha ChileCompra |
| 807 | DUS |
| 808 | B/L (Conocimiento de embarque) |
| 809 | AWB (Air Will Bill) |
| 810 | MIC/DTA |
| 811 | Carta de Porte |
| 812 | Resolución del SNA que califica Servicios de Exportación |
| 813 | Pasaporte |
| 814 | Certificado de Depósito Bolsa de Productos de Chile |
| 815 | Vale de Prenda Bolsa de Productos de Chile |
| 820 | Código de Inscripción en el Registro de Acuerdos con Plazo de Pago Excepcional |

*(La bitácora del documento menciona además el código 888: Referencia a Archivo adjunto,
incorporado en 2005, que no figura en la tabla final de la pág. 41.)*

Si el valor de `TpoDocRef` es alfabético no hay validación y el contribuyente puede usarlo para
referenciar documentos no tributarios distintos de los especificados.

### 8.b Reglas de referencia en exportación

- En factura de exportación se puede indicar **un DUS por factura**.
- En exportaciones por vía terrestre y servicio de transporte internacional
  (`IndServicio` = 5), se puede indicar **solo una Carta de Porte por factura**.
- En NC y ND de exportación es **obligatorio referenciar la factura de exportación** que
  modifican.
- Por cada Guía de Despacho se puede referenciar **solo 1 DUS o MIC**.

### 8.c Uso de `RUTOtr`

Se aplica cuando: (i) se emiten Facturas de Compra por bienes y se debe referenciar la Guía de
Despacho emitida por el vendedor; (ii) se emiten NC/ND que referencian un DTE emitido por un
contribuyente fusionado o absorbido. **No** se usa para referenciar una Orden de Compra (no es
documento tributario).

### 8.d `CodRef` — Código de referencia

| Valor | Significado |
|---|---|
| 1 | **Anula** documento de referencia (NC que elimina factura de venta, ND o factura de compra; ND que elimina una NC) |
| 2 | **Corrige texto** del documento de referencia (NC "fe de erratas"; el monto de las líneas debe ser 0) |
| 3 | **Corrige montos** de otro documento (NC o ND) |

Los casos con `CodRef` 1 y 2 (anulación y corrección de texto) **deben tener un único documento
de referencia**.

---

## 9. F — COMISIONES Y OTROS CARGOS — `<Comisiones>`

De 0 a **20 líneas**. **No modifican la base del impuesto** de la operación principal.
**Obligatoria en Liquidaciones-Factura**; opcional en Facturas de Compra Electrónicas y en
NC/ND electrónicas que corrijan Facturas de Compra. (Solo aplica a NC, ND, FC y LIQ.)

| # | Campo / Tag | Descripción | Tipo | Largo | I | Obligatoriedad (NC/ND/FC/LIQ) |
|---|---|---|---|---|---|---|
| 1 | `NroLinCom` | Número secuencial, de 1 a 20 (si se incluye la zona, al menos una línea) | NUM | 2 | N | 1-1-1-1 |
| 2 | `TipoMovim` | `C` (comisión) u `O` (otros cargos) | ALFA | 1 | N | 1-1-1-1 |
| 3 | `Glosa` | Especificación de la comisión u otro cargo | ALFA | 60 | I | 1-1-1-1 |
| 4 | `TasaComision` | Valor porcentual: 2 enteros + 2 decimales | NUM | 4 | I | 3-3-3-3 |
| 5 | `ValComNeto` | Valor neto de la comisión/otro cargo. Puede ser 0 si `ValComExe` ≠ 0. En Liquidaciones-Factura puede ser negativo | NUM | 18 | I | 1-1-1-1 |
| 6 | `ValComExe` | Valor exento de la comisión/otro cargo. Puede ser 0 si `ValComNeto` ≠ 0. En Liquidaciones-Factura puede ser negativo | NUM | 18 | I | 1-1-1-1 |
| 7 | `ValComIVA` | IVA de la comisión/otros cargos = valor × tasa IVA. En Liquidaciones-Factura puede ser negativo | NUM | 18 | I | 2-2-2-2 |

Los totales de esta zona se reflejan en el encabezado en `ValComNeto`, `ValComExe` y
`ValComIVA` de `<Totales>`, y se **restan** en la fórmula de `MntTotal`.

---

## 10. G/H/I — Timbre electrónico, fecha de firma y firma digital

> **Nota para openfactura-ruby**: estas tres zonas las genera la plataforma (OpenFactura firma
> y timbra el DTE). Se documentan solo conceptualmente.

### G — Timbre Electrónico SII (TED)

- Contiene la **firma electrónica sobre los campos representativos del DTE**, la fecha y hora
  de generación del timbre, y el **CAF** (Código de Autorización de Folios) entregado por el
  SII.
- Campos representativos (ejemplo dado por el PDF): RUT Emisor, RUT Receptor, Tipo de
  Documento, Folio, IVA, Monto Neto y CAF.
- Corresponde a la información del **código de barras bidimensional PDF417** impreso en la
  representación gráfica, y permite validar el documento impreso.
- Tipo ALFA. Descripción detallada: Anexos del "Instructivo de Generación de Documentos" del
  SII (en el schema XML corresponde al elemento `TED`).

### H — Fecha y hora de firma del documento

- Formato `AAAA-MM-DDTHH:MI:SS` (19 caracteres, ALFA). Fecha y hora válidas.
  (En el schema XML corresponde al elemento `TmstFirma`.)

### I — Firma digital del documento completo

1. **Certificado digital**: información pública del certificado necesaria para validar la
   firma. Debe estar vigente, no revocado y autorizado ante el SII al momento de firmar.
2. **Firma electrónica** sobre todo el documento (Encabezado, Detalle, Descuentos-Recargos,
   Información de Referencia, Fecha y Hora de Firma y Timbre Electrónico), según el estándar
   **XML Digital Signature** (`http://www.w3.org/TR/2002/REC-xmldsig-core-20020212/`) y el
   schema XML del DTE definido por el SII.

### Formato de impresión

El capítulo de formato de impresión fue eliminado del documento (v. 29/09/2014): está contenido
en el "Manual de Muestras Impresas" en `www.sii.cl`, Sistema de Facturación de Mercado, opción
Ayudas.

---

## 11. Reglas de montos, cálculo y validación (síntesis normativa)

1. **Moneda y decimales**: en pesos chilenos los montos son enteros (los decimales solo se
   indican cuando son significativos, separados por punto; sin separador de miles). Los campos
   "en otra moneda" aceptan 14 enteros + 4 decimales; cantidades y precios unitarios del
   detalle, 12 enteros + 6 decimales.
2. **Cuadratura por línea**: `MontoItem` = (`PrcItem` × `QtyItem`) − `DescuentoMonto` +
   `RecargoMonto`.
3. **Cuadratura del neto**: `MntNeto` = Σ `MontoItem` de ítems afectos − descuentos globales +
   recargos globales asignados a afectos. `MntExe` = ídem para ítems exentos/no afectos.
4. **IVA**: `IVA` = `MntNeto` × `TasaIVA`. `IVAProp`/`IVATerc` < `IVA`.
5. **Montos brutos**: si `MntBruto` = 1 (líneas expresadas con IVA incluido, solo documentos
   sin impuestos adicionales), el neto se obtiene dividiendo por (1 + tasa de IVA).
6. **Total**: fórmula de `MntTotal` en 4.5.a. En exportación, `MntTotal` = 0 si
   `FmaPagExp` = 21 (sin pago).
7. **Valores negativos**: solo se admiten en **Liquidaciones-Factura** para: `MntNeto`,
   `ValComNeto`, `MntExe`, `ValComExe`, `IVA`, `IVAProp`, `IVATerc`, `ValComIVA`, `MntTotal`,
   `MntTotOtrMnda`, `MontoItem`, `MontoItemOtrMnda` y valores de Comisiones. `MontoNF`,
   `MontoPeriodo`, `SaldoAnterior` y `VlrPagar` pueden ser negativos en general.
8. **Errores aritméticos no rechazan**: el SII rechaza solo por ausencia de campos marcados
   con (*) o violaciones estructurales; los errores de contenido (p. ej. IVA mal calculado) se
   corrigen emitiendo Nota de Crédito o Nota de Débito.
9. **Documento exento**: si todos los ítems son exentos (`IndExe` = 1), debe emitirse tipo 34,
   no 33. En una factura exenta global no se usa `IndExe` en las líneas.
10. **Exportación**: se emite en moneda extranjera (`TpoMoneda` en Totales) pero es obligatorio
    informar en `<OtraMoneda>` la conversión a pesos chilenos (`TpoMoneda` = `PESO CL`,
    `TpoCambio` del Banco Central a la fecha de emisión, `MntExeOtrMnda` y `MntTotOtrMnda`).
11. **Flete y seguro** (`MntFlete`, `MntSeguro`): estrictamente mayores que cero cuando se
    informan.
12. **Límites de repetición**: Detalle ≤ 60 líneas; Subtotales ≤ 20; Descuentos/Recargos
    globales ≤ 20; Referencias ≤ 40; Comisiones ≤ 20; `MntPagos` ≤ 30; `TipoBultos` ≤ 10;
    códigos por ítem (`CdgItem`) ≤ 5; `Subcantidad` ≤ 5; sub-descuentos/sub-recargos ≤ 5;
    `ImptoReten` (encabezado) ≤ 20; `CodImpAdic` (por línea) ≤ 2; `Telefono` emisor ≤ 2;
    `Acteco` ≤ 4; `OtrMnda` del detalle ≤ 2.

### Campos cuya ausencia provoca rechazo del DTE — columna (*)

`VERSIÓN`, `TipoDTE`, `Folio`, `FchEmis`, `RUTEmisor`, `RUTRecep`, `MntTotal` (encabezado) y
`NroLinDet`, `NmbItem`, `MontoItem` (detalle).

---

## 12. Codificación de tipos de impuestos y recargos (`TipoImp` / `CodImpAdic`)

Tabla completa del punto 4 del documento. La columna "Cód. ret. total" es el **código de cambio
de sujeto en retención total** asociado (se usa cuando se retuvo el total del IVA por ser NDF —
no declarante fiscal).

| Código | Cód. ret. total | Nombre | Tasa / descripción | Documentos en que se aplica |
|---|---|---|---|---|
| 14 | — | IVA de margen de comercialización | Para facturas de venta del contribuyente | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 15 | — | IVA retenido total | IVA retenido en facturas de compra. Suma de retenciones con tasa de IVA | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 17 | — | IVA anticipado faenamiento carne | Tasa **5%** sobre monto base faenamiento; IVA anticipado cobrado al cliente | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 18 | — | IVA anticipado carne | Tasa **5%**; IVA anticipado cobrado al cliente | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 19 | — | IVA anticipado harina | Tasa **12%**; IVA anticipado cobrado al cliente | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 23 | — | Impuesto adicional Art. 37 letras a, b, c | Tasa **15%**: a) artículos de oro, platino, marfil; b) joyas, piedras preciosas; c) pieles finas | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 24 | — | DL 825/74, Art. 42 letra b | Tasa **31,5%**: licores, piscos, whisky, aguardientes y vinos licorosos o aromatizados | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 25 | — | DL 825/74, Art. 42 letra c | Tasa **20,5%**: vinos | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 26 | — | DL 825/74, Art. 42 letra c | Tasa **20,5%**: cervezas y bebidas alcohólicas | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 27 | — | DL 825/74, Art. 42 letra a | Tasa **10%**: bebidas analcohólicas y minerales | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 271 | — | DL 825/74, Art. 42 letra a) inciso segundo | Tasa **18%**: bebidas analcohólicas y minerales con elevado contenido de azúcares (según ley) | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 28 | — | Impuesto específico diésel | **1,5 UTM por m³**, traspasado al comprador (Art. 6 Ley 18.502; Arts. 1° y 3° DS 311/86). En facturas del vendedor (IEV); en IEC solo si el comprador tiene derecho al crédito | Facturas del vendedor |
| 30 | 301 | IVA retenido legumbres | Normalmente **10%** de retención (retención parcial en IEC; total si NDF) | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 31 | — | IVA retenido silvestres | Retención del **total del IVA** | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 32 | 321 | IVA retenido ganado | Normalmente **8%** de retención | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 33 | 331 | IVA retenido madera | Normalmente **8%** de retención | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 34 | 341 | IVA retenido trigo | Normalmente **4%** de retención | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 35 | — | Impuesto específico gasolina | **4,5 a 6 UTM por m³** (Art. 6 Ley 18.502; Arts. 1° y 3° DS 311/86). No da derecho a crédito; rebaja transitoria componente variable Ley 20.259 | Facturas del vendedor (IEV) |
| 36 | 361 | IVA retenido arroz | Normalmente **10%** de retención | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 37 | 371 | IVA retenido hidrobiológicas | Normalmente **10%** de retención | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 38 | — | IVA retenido chatarra | Retención del **total del IVA** | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 39 | — | IVA retenido PPA | Retención del **total del IVA** | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 41 | — | IVA retenido construcción | Se retiene el **total del IVA** | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 44 | — | Impuesto adicional Art. 37 letras e, h, i, l | Tasa **15%** en 1ª venta: a) alfombras y tapices; b) casas rodantes; c) caviar; d) armas de aire o gas | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 45 | — | Impuesto adicional Art. 37 letra j | Tasa **50%** en 1ª venta: pirotecnia | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 46 | — | IVA retenido oro | Retención del **100% del IVA** | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 47 | — | IVA retenido cartones | **Retención total** | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 48 | 481 | IVA retenido frambuesas | Retención **14%** | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 49 | — | Factura de compra sin retención | **0% de retención** (hoy utilizada solo por Bolsa de Productos de Chile; validado por el sistema) | FC emitida (45, 46), NC (60, 61), ND (55, 56) |
| 50 | — | IVA de margen de comercialización de instrumentos de prepago | Para facturas de venta del contribuyente | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 51 | — | Impuesto gas natural comprimido | **1,93 UTM/KM³** (Art. 1° Ley 20.052) | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 52 | — | Impuesto gas licuado de petróleo | **1,40 UTM/M³** (Art. 1° Ley 20.052) | Facturas (30, 33), NC (60, 61), ND (55, 56) |
| 53 | — | Impuesto retenido suplementeros | Retención del **0,5%** sobre el precio de venta al público (Art. 74 N°5 Ley de la Renta) | Facturas (30, 33), NC (60, 61), ND (55, 56) |

Notas de la tabla:

- Los códigos de retención con "cambio de sujeto" (30/32/33/34/36/37/48) registran la
  retención parcial en el IEC; si se retuvo el total del IVA (receptor NDF) se usa el registro
  de retención total (códigos 301/321/331/341/361/371/481).
- Código 29 fue eliminado (solo podía usarse en IEC por transportistas de carga); códigos 16 y
  40 fueron eliminados en revisiones anteriores.
- En el detalle del DTE, el código va en `CodImpAdic` (hasta 2 por línea); en el encabezado, el
  par código/tasa/monto va en la tabla `ImptoReten` (`TipoImp`, `TasaImp`, `MontoImp`).

---

## 13. Unidades de medida

El documento del SII **no incluye una tabla propia de unidades de medida**. Los campos
`UnmdItem` y `UnmdRef` son glosas ALFA de hasta 4 caracteres sin validación, **salvo** en
documentos de exportación y guías con `IndTraslado` 8/9, donde debe usarse la tabla
"Unidades de Medida" de **Aduana** (`www.aduana.cl`) — igual que `CodUnidMedTara`,
`CodUnidPesoBruto` y `CodUnidPesoNeto` (códigos NUM de 2 dígitos).

---

## 14. Chuleta rápida para emisión vía OpenFactura

- El payload JSON de OpenFactura replica la estructura SII: `Encabezado` (`IdDoc`, `Emisor`,
  `Receptor`, `Totales`…), `Detalle[]`, `DscRcgGlobal[]`, `Referencia[]`, con los mismos
  nombres de tags de este documento.
- El **TED (timbre)**, la **firma digital** y el manejo de **CAF/folios** los resuelve la
  plataforma; el SDK no los construye.
- Mínimo típico de una Factura Electrónica (33) afecta: `IdDoc` (`TipoDTE`, `Folio` si aplica,
  `FchEmis`), `Emisor` (`RUTEmisor`, `RznSoc`, `GiroEmis`, `Acteco`, `DirOrigen`,
  `CmnaOrigen`), `Receptor` (`RUTRecep`, `RznSocRecep`, `GiroRecep`, `DirRecep`, `CmnaRecep`),
  `Totales` (`MntNeto`, `TasaIVA`, `IVA`, `MntTotal`), y al menos una línea de `Detalle`
  (`NroLinDet`, `NmbItem`, `MontoItem`, más `QtyItem`/`PrcItem` cuando corresponda).
- Para documento exento: tipo 34 con `MntExe` (obligatorio) y sin `IVA`/`TasaIVA`; o líneas
  puntuales exentas en un 33 con `IndExe` = 1 por línea.
- NC (61) y ND (56) **siempre** llevan al menos una `Referencia` con `TpoDocRef`, `FolioRef`,
  `FchRef` y `CodRef` (1 anula / 2 corrige texto / 3 corrige montos).
- Guía de despacho (52) **siempre** lleva `IndTraslado`.
