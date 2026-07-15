# Boleta Electrónica SII — Referencia de formato (tipos 39 y 41)

Documento de referencia destilado de dos versiones oficiales del documento "Formato Boletas Electrónicas" del Servicio de Impuestos Internos (SII) de Chile:

| Fuente | Título | Versión | Fecha | Páginas |
|---|---|---|---|---|
| `boletas_elec.pdf` (boletas_elec_020.pdf) | FORMATO BOLETAS ELECTRÓNICAS | **2.22** | **2020-07-20** | 15 |
| `formato_boleta_electronica.pdf` | FORMATO BOLETAS ELECTRÓNICAS DE VENTAS Y SERVICIOS | **4.2** | **2025-09-08** | 19 |

**Ambos PDFs son el mismo documento de formato técnico en versiones distintas** (no son normativa/proceso vs formato). La versión 4.2 (2025) reemplaza a la 2.22 (2020) y es la fuente primaria de esta referencia; las diferencias entre versiones se documentan en la sección 6. Nota: en el PDF v2.22 el pie de página dice "Versión 2.0 2010-07-12" (pie desactualizado); la portada indica Versión 2.22, 2020-07-20.

Los tags XML del SII listados aquí son los mismos nombres de campo que usa la API de OpenFactura en JSON (p. ej. `TipoDTE`, `Folio`, `IndServicio`, `MntTotal`).

---

## 1. Qué son las boletas electrónicas (39 y 41)

Según `<TipoDTE>`:

- **39: Boleta Electrónica** (afecta a IVA)
- **41: Boleta No Afecta o Exenta Electrónica**

Obligaciones generales del emisor (sección Introducción, ambas versiones):

- Mantener las boletas en la empresa durante **seis años** en formato XML.
- Disponibles para consulta en línea en la sucursal para el mes en curso y los dos meses anteriores; el SII puede pedir períodos anteriores en medios tecnológicos.
- Quien emite boletas electrónicas en una sucursal debe emitir la totalidad de su documentación de forma electrónica en dicha sucursal.
- Generar y enviar diariamente al SII un **"Reporte de Consumo de Folios"** (así figura textualmente en la introducción de ambas versiones, incluida la v4.2 de 2025).
- Publicar las boletas emitidas en un sitio web de consulta para los clientes por **tres meses** desde la emisión, señalando el sitio bajo el timbre electrónico (p. ej. "Verifique documento: http://www.consultaboletaelectronica.empresa.cl"; con la obligatoriedad vigente, la leyenda "verifique en www.sii.cl", pudiendo agregar opcionalmente la URL propia).

**Tamaño de envío al SII**: máximo **500 boletas por envío** (el SII valida el formato XML del envío y la firma electrónica sobre el mismo).

### Diferencias clave vs. facturas electrónicas (según estos documentos)

El propio formato indica: "Los nombres y características son similares a la Factura electrónica". Diferencias que se desprenden del documento:

- **Montos con IVA incluido**: en boletas, el precio unitario y los valores de línea son **brutos (con IVA)** por defecto; en facturas son netos. Ver sección 4.
- **Receptor sin identificación obligatoria**: `<RUTRecep>` admite `0` (cliente identificado por código interno) o el **RUT genérico 66.666.666-6** para boletas de ventas y servicios no periódicos ni domiciliarios. En factura el RUT del receptor real es obligatorio. Excepción (v4.2, Ley 21.713): con Monto Total > 135 UF el RUT debe corresponder al cliente receptor real.
- **El IVA no se desglosa en la representación impresa por línea**: la boleta informa `<IVA>` como total calculado desde el monto neto (que a su vez se deriva de los brutos).
- **Zona Detalle condicional**: desde el cambio 2019-03-11 la zona "Detalle" pasó de obligatoria a **condicional** (obligatoriedad 2); el encabezado con el monto total es lo siempre obligatorio.
- **Timbre**: mismo formato de firma/timbre que la factura (PDF417 sobre datos representativos + CAF).

---

## 2. Formato del documento: zonas y campos

### Códigos de obligatoriedad de campo

- **1**: Dato obligatorio, siempre.
- **2**: Dato condicional — obligatorio solo si se cumple cierta condición.
- **3**: Opcional.
- **4**: (solo v2.22) Obligatorio solo en el documento impreso, no es obligatorio guardarlo en forma electrónica. **Eliminado en v4.2** (cambio 2024-06-01: se reemplaza 4 por 3).
- **0**: usado en las tablas para "no aplica" (p. ej. `<IndMntNeto>`, `<MntNeto>` e `<IVA>` en boleta exenta).

### Columna I (representación digital o impresa)

- **N** = No es obligatorio que esté impreso.
- **I** = Debe estar impreso, en formato editado.
- **P** = Debe estar impreso traduciendo el código a palabras (p. ej. el tipo de documento va codificado en el XML pero en palabras en la representación).

### Obligatoriedad de zonas (v4.2)

| Zona | Obligatoriedad |
|---|---|
| Encabezado | 1 |
| Detalle | 2 |
| Subtotales Informativos | 2 |
| Descuentos y Recargos | 2 |
| Datos de Referencia | 3 *(en v2.22 era 4)* |
| Datos de Georreferenciación | 2 *(solo v4.2; la sección la describe como "datos opcionales")* |
| Timbre | 1 |
| Firma | 1 |

### A. Encabezado

Identificación del documento, emisor, receptor y monto total. Obligatoriedad indicada como Boleta (39) / Boleta exenta (41). Fuente: v4.2; diferencias v2.22 anotadas.

| # | Campo | Tag | Largo | Tipo | I | 39 | 41 | Descripción / Validación |
|---|---|---|---|---|---|---|---|---|
| 1 | Versión | *(sin tag en el documento)* | 3 | ALFA | N | 1 | 1 | Versión del formato utilizado. Valor: `1.0` |
| 2 | Tipo de Documento | `<TipoDTE>` | 2 | NUM | P | 1 | 1 | 39: Boleta Electrónica; 41: Boleta No Afecta o Exenta Electrónica |
| 3 | Folio Documento | `<Folio>` | 10 | NUM | I | 1 | 1 | Folio autorizado por el SII. Campo NUM |
| 4 | Emisión Contable | `<FchEmis>` | 10 | ALFA | I | 1 | 1 | Fecha de emisión `AAAA-MM-DD`. Válida entre 2002-08-01 y 2050-12-31 |
| 5 | Indicador Servicio | `<IndServicio>` | 1 | NUM | N | 1 | 1 | Tipo de transacción. Ver sección 3 |
| 6 | Indicador Montos Netos | `<IndMntNeto>` | 1 | NUM | N | 3 | 0 | Valor `2`: las líneas de detalle indican **montos netos** (no incluyen IVA). **No aplica en boleta exenta**. Ver sección 4 |
| 7 | Periodo Desde | `<PeriodoDesde>` | 10 | ALFA | I | 2 | 2 | Se usa para servicios periódicos |
| 8 | Periodo Hasta | `<PeriodoHasta>` | 10 | ALFA | I | 2 | 2 | Se usa para servicios periódicos |
| 9 | Fecha de vencimiento (pago) | `<FchVenc>` | 10 | ALFA | I | 2 | 2 | `AAAA-MM-DD`, válida 2002-08-01 a 2050-12-31. Obligatorio en servicios periódicos domiciliarios |
| 10 | Medio de pago | `<MedioPago>` | 1 | NUM | N | 2 | 2 | **Solo v4.2** (agregado 2024-12-31). Ver sección 7 |
| 11 | Rut Emisor | `<RUTEmisor>` | 10 | ALFA | I | 1 | 1 | Con guion y dígito verificador. Cuerpo numérico entre 100.000 y 99 millones; DV alfanumérico 0-9 o K |
| 12 | Nombre o Razón Social Emisor | `<RznSocEmisor>` | 100 | ALFA | N | 3 | 3 | Dato opcional. *(v2.22: obligatoriedad 4, columna I = I)* |
| 13 | Giro del negocio del Emisor | `<GiroEmisor>` | 80 | ALFA | N | 3 | 3 | Opcional. Basta registrar solo el giro de la transacción. *(v2.22: obligatoriedad 4)* |
| 14 | Código sucursal | `<CdgSIISucur>` | 9 | NUM | N | 2 | 2 | Código numérico entregado por el SII que identifica la sucursal. Si no hay sucursales, se puede omitir |
| 15 | Dirección Origen | `<DirOrigen>` | 70 | ALFA | N | 3 | 3 | Dirección de sucursal que despacha bienes o que emite el documento. Opcional. *(v2.22: obligatoriedad 4)* |
| 16 | Comuna Origen | `<CmnaOrigen>` | 20 | ALFA | N | 3 | 3 | Opcional. *(v2.22: 4)* |
| 17 | Ciudad Origen | `<CiudadOrigen>` | 20 | ALFA | N | 3 | 3 | Opcional. *(v2.22: 4)* |
| 18 | Rut Receptor | `<RUTRecep>` | 10 | ALFA | N | 1 | 1 | Con guion y DV. Debe venir un RUT válido **o** `0` cuando el cliente se identifica solo con código interno. Solo en boletas de ventas y servicios no periódicos ni domiciliarios, si no se cuenta con RUT ni código interno se usa el **RUT genérico `66.666.666-6`**. Se imprime si es distinto de 0 y de 66.666.666-6. **v4.2**: debe corresponder al RUT del cliente receptor cuando Monto Total > 135 UF (Ley 21.713) |
| 19 | Código Interno del Cliente | `<CdgIntRecep>` | 20 | ALFA | N | 2 | 2 | Identificación interna del receptor (código de cliente, número de medidor, etc.). Si RUT es 0, obligatoriamente debe ir el código interno. **v4.2**: "Dato obligatorio si Indicador Servicio = 3 y RUT = 0, o Monto Total > 135 UF (Ley 21.713)" (en la extracción del PDF esta frase aparece entre este campo y el siguiente; en v2.22 la condición "obligatorio si Indicador Servicio=3 y RUT=0" pertenecía a `<RznSocRecep>`) |
| 20 | Nombre Receptor | `<RznSocRecep>` | 100 | ALFA | N | 2 | 2 | **v4.2**: "Se debe imprimir cuando Monto total > 135 UF. Opcional en otros casos". Largo pasó a 100 en 2025-09-08. *(v2.22: largo 40, obligatoriedad 3, desc. "Dato obligatorio si Indicador Servicio = 3 y RUT = 0, opcional en otros casos")* |
| 21 | Contacto Receptor | `<Contacto>` | 80 | ALFA | N | 3 | 3 | Nombre o código adicional para identificar al cliente |
| 22 | Correo Receptor | `<CorreoRecep>` | 80 | ALFA | N | 3 | 3 | **Solo v4.2** (agregado 2024-12-31; descripción/obligatoriedad modificadas 2025-09-08). Correo electrónico del cliente receptor. Sin validación |
| 23 | Número de contacto receptor | `<TelefonoRecep>` | 20 | ALFA | N | 3 | 3 | **Solo v4.2**. Teléfono de contacto del cliente receptor. Sin validación |
| 24 | Dirección Receptor | `<DirRecep>` | 70 | ALFA | I | 2 | 2 | Dirección donde se otorga el servicio (servicios en domicilio) o a la que se envían bienes; si es servicio móvil, dirección de residencia del cliente. **Obligatorio si IndServicio = 1 o 2; opcional si IndServicio = 3** |
| 25 | Comuna Receptor | `<CmnaRecep>` | 20 | ALFA | N | 2 | 2 | Ídem anterior. Sin validación |
| 26 | Ciudad Receptor | `<CiudadRecep>` | 20 | ALFA | N | 3 | 3 | Ídem. Sin validación |
| 27 | Dirección postal | `<DirPostal>` | 70 | ALFA | N | 3 | 3 | Otra dirección registrada. Sin validación |
| 28 | Comuna Postal | `<CmnaPostal>` | 20 | ALFA | N | 3 | 3 | Sin validación |
| 29 | Ciudad Postal | `<CiudadPostal>` | 20 | ALFA | N | 3 | 3 | Sin validación |
| 30 | Rut Proveedor de software | `<RutProvSW>` | 10 | ALFA | N | 2 | 2 | **Solo v4.2** (agregado 2023-06-01). RUT de la empresa proveedora del sistema de emisión de boletas electrónicas, con guion y DV. Si es desarrollo propio, informar el RUT del emisor. Cuerpo 100.000–99 millones, DV 0-9 o K |
| 31 | Nombre o Razón Social Proveedor | `<RznSocProvSW>` | 100 | ALFA | N | 3 | 3 | **Solo v4.2**. Nombre o razón social del RUT proveedor de software. Si es desarrollo propio, **no informar**. Largo pasó a 100 en 2025-09-08 |
| 32 | Monto neto | `<MntNeto>` | 18 | NUM | N | 1 | 0 | Solo válido si la boleta no es exenta. Valor numérico > 0. Ver fórmula en sección 4 |
| 33 | Monto exento | `<MntExe>` | 18 | NUM | N | 2 | 2 | Suma de "Valor por línea de detalle" para Indicador Exención = 1 |
| 34 | IVA | `<IVA>` | 18 | NUM | I | 1 | 0 | Solo válido si la boleta no es exenta. "Igual a la tasa (%) de IVA aplicada al Monto neto" |
| 35 | Monto Total | `<MntTotal>` | 18 | NUM | I | 1 | 1 | Se calcula como **Monto neto + IVA + Monto Exento** |
| 36 | Monto no Facturable | `<MontoNF>` | 18 | NUM | N | 2 | 2 | Suma de montos de bienes/servicios con Indicador exención = **2 y 6** (v4.2). Puede ser negativo. *(v2.22: el tag era `<MntoNF>` — renombrado a `<MontoNF>` el 2022-12-28 — y la descripción decía solo Indicador exención = 2)* |
| 37 | Total período | `<TotalPeriodo>` | 18 | NUM | N | 2 | 2 | **Monto Total + Monto no Facturable**. Sin validación |
| 38 | Saldo anterior | `<SaldoAnterior>` | 18 | NUM | N | 3 | 3 | Solo con fines de ilustrar con claridad el cobro. Puede ser negativo |
| 39 | Valor a pagar | `<VlrPagar>` | 18 | NUM | N | 3 | 3 | Valor cobrado: **Valor total + Saldo anterior**. Puede ser negativo o cero |

*(La numeración de filas corresponde a v4.2; en v2.22 los campos 10, 22, 23, 30 y 31 no existen y la numeración corre distinta.)*

### B. Detalle de Productos o Servicios

Información por ítem. **Máximo 1000 ítems.** Zona condicional (obligatoriedad 2): si se incluye, debe haber al menos una línea.

| # | Campo | Tag | Largo | Tipo | I | 39 | 41 | Descripción / Validación |
|---|---|---|---|---|---|---|---|---|
| 1 | N° de Línea o N° Secuencial | `<NroLinDet>` | 4 | NUM | N | 1 | 1 | Número del ítem, de 1 a 1000. Secuencial |
| 2 | Tipo código | `<TpoCodigo>` | 10 | ALFA | N | 3 | 3 | Codificación: EAN13, PLU, DUN14, INT1, INT2, EAN128, etc. (hasta 5 tipos de códigos). Sin validación |
| 3 | Código del ítem | `<VlrCodigo>` | 35 | ALFA | N | 3 | 3 | Código del producto según tipo indicado en el campo anterior. Sin validación (máx. 35 bytes) |
| 4 | Indicador exención | `<IndExe>` | 1 | NUM | N | 2 | 2 | `1`: producto o servicio exento o no afecto. `2`: no facturable. `6`: no facturable (negativo). Si es 2, no se considera para el cálculo del IVA del período. No se usa para saldo anterior |
| 5 | Ítem Espectáculo | `<ItemEspectaculo>` | 2 | NUM | N | 2 | 2 | `01`: TICKET; `02`: VALOR SERVICIO (p. ej. comisión por venta de ticket o acercamiento). **Obligatorio si IndServicio = 4** |
| 6 | Rut Mandante | `<RUTMandante>` | 10 | ALFA | N | 3 | 3 | RUT de la empresa mandante de la boleta, con guion y DV. Cuerpo 100.000–99 millones, DV 0-9 o K |
| 7 | Nombre del ítem | `<NmbItem>` | 80 | ALFA | I | 1 | 1 | Nombre del producto o servicio. Si `<ItemEspectaculo>` no es nulo, el nombre debe tener relación con "TICKET" o "VALOR SERVICIO - COMISIÓN". **v4.2**: se debe informar de forma clara su descripción cuando Monto Total > 135 UF (Ley 21.713) |
| — | **ÁREA INFO TICKET** | | | | | 2 | 2 | **Obligatoria si `<ItemEspectaculo>` = 01.** Campos 8–17 |
| 8 | Folio Ticket | `<FolioTicket>` | 6 | NUM | I | 1 | 1 | Numeración única para el evento |
| 9 | Fecha Generación Ticket | `<FchGenera>` | 16 | ALFA | N | 1 | 1 | `AAAA-MM-DDThh:mm:ss`, válida entre 2010-03-10T00:00:00 y 2050-12-31T23:59:59 |
| 10 | Nombre Evento | `<NmbEvento>` | 80 | ALFA | I | 1 | 1 | Nombre del espectáculo |
| 11 | Tipo Ticket | `<TpoTicket>` | 10 | ALFA | I | 1 | 1 | P. ej.: Adulto, Niño, etc. |
| 12 | Código del Evento | `<CdgEvento>` | 5 | ALFA | I | 1 | 1 | Código asociado al evento |
| 13 | Fecha y Hora del Evento | `<FchEvento>` | 16 | ALFA | I | 1 | 1 | `AAAA-MM-DDThh:mm:ss`, mismo rango válido que `<FchGenera>` |
| 14 | Lugar del Evento | `<LugarEvento>` | 80 | ALFA | I | 1 | 1 | Dirección o identificación del recinto |
| 15 | Ubicación en el Evento | `<UbicEvento>` | 20 | ALFA | I | 1 | 1 | Sector/sección |
| 16 | Fila Ubicación | `<FilaUbicEvento>` | 3 | ALFA | I | 3 | 3 | Fila de la ubicación |
| 17 | Asiento Ubicación | `<AsntoUbicEvento>` | 3 | NUM | I | 3 | 3 | N° de asiento |
| — | **FIN ÁREA INFO TICKET** | | | | | | | |
| 18 | Descripción Adicional | `<DscItem>` | 1000 | ALFA | I | 3 | 3 | Descripción adicional; se usa para packs, servicios con detalle. Sin validación |
| 19 | Cantidad | `<QtyItem>` | 18 | NUM | I | 2 | 2 | 12 enteros y 6 decimales. Se debe indicar en caso de venta de mercaderías o productos |
| 20 | Unidad de Medida | `<UnmdItem>` | 4 | ALFA | I | 3 | 3 | Glosa con unidad de medida. Sin validación |
| 21 | Precio Unitario | `<PrcItem>` | 18 | NUM | I | 2 | 2 | 12 enteros y 6 decimales. **Este precio es bruto con IVA, excepto cuando el Indicador Montos Netos tiene el valor 2.** Se debe indicar en caso de venta de mercaderías o productos |
| 22 | Porcentaje de Descuento | `<DescuentoPct>` | 5 | NUM | N | 3 | 3 | 3 enteros y 2 decimales. Valor entre 0 y 100 incluidos |
| 23 | Monto Descuento | `<DescuentoMonto>` | 18 | NUM | I | 2 | 2 | Totaliza el descuento aplicado al ítem. **Monto bruto con IVA, excepto con IndMntNeto = 2.** Si hay descuento en porcentaje, debe ir el monto del descuento |
| 24 | Porcentaje de Recargo | `<RecargoPct>` | 5 | NUM | N | 3 | 3 | 3 enteros y 2 decimales. Entre 0 y 100 incluidos |
| 25 | Monto Recargo | `<RecargoMonto>` | 18 | NUM | I | 2 | 2 | Totaliza el recargo aplicado al ítem. **Bruto con IVA, excepto con IndMntNeto = 2.** Si hay recargo en porcentaje, debe ir el monto |
| 26 | Valor por línea de detalle | `<MontoItem>` | 18 | NUM | I | 1 | 1 | **(Precio Unitario × Cantidad) − Monto Descuento + Monto Recargo. Valor bruto (con IVA), excepto cuando IndMntNeto = 2** |

### C. Subtotales Informativos

De 0 a 20 líneas. **No aumentan ni disminuyen la base del impuesto ni modifican los totalizadores**; son informativos, para agrupar ítems a gusto del contribuyente. En la representación impresa pueden intercalarse entre líneas de detalle o agruparse en sección aparte.

| # | Campo | Tag | Largo | Tipo | I | 39 | 41 | Descripción / Validación |
|---|---|---|---|---|---|---|---|---|
| 1 | N° de Línea o N° Secuencial | `<NroSTI>` | 2 | NUM | N | 1 | 1 | Número de subtotal, de 1 a 20 |
| 2 | Glosa | `<GlosaSTI>` | 80 | ALFA | I | 3 | 3 | Especificación del subtotal |
| 3 | Orden de impresión | `<OrdenSTI>` | 2 | NUM | N | 3 | 3 | Orden/lugar de impresión del subtotal en la representación. Para uso del emisor |
| 4 | Valor Sub Total Neto | `<SubTotNetoSTI>` | 18 | NUM | I | 3 | 3 | 16 enteros, 2 decimales |
| 5 | Valor Sub Total IVA | `<SubTotIVASTI>` | 18 | NUM | I | 3 | 3 | 16 enteros, 2 decimales |
| 6 | Valor Sub Total Impuesto Adicional | `<SubTotAdicSTI>` | 18 | NUM | I | 2 | 3 | 16 enteros, 2 decimales. Obligatorio en transacciones de las letras a), b) y c) del Art. 37 de la Ley de IVA |
| 7 | Valor Sub Total Exento | `<SubTotExeSTI>` | 18 | NUM | I | 3 | 3 | 16 enteros, 2 decimales |
| 8 | Valor del Subtotal | `<ValSubtotSTI>` | 18 | NUM | I | 3 | 3 | 16 enteros y 2 decimales. Aplica en subtotales en $ u otra moneda |
| 9 | Línea de Detalle | `<LineasDeta>` | 18 | NUM | N | 3 | 3 | TABLA de líneas de detalle que se agrupan en el subtotal. Hasta 60 repeticiones |

### D. Información de Descuentos o Recargos (globales)

De 0 a 20 líneas. **Estos sí aumentan o disminuyen la base del impuesto.** Llevan glosa que especifica a qué ítems aplican (p. ej. descuento global a un tipo de producto, o por pago contado sobre todos los ítems).

| # | Campo | Tag | Largo | Tipo | I | 39 | 41 | Descripción / Validación |
|---|---|---|---|---|---|---|---|---|
| 1 | N° de Línea o N° Secuencial | `<NroLinDR>` | 3 | NUM | N | 1 | 1 | Número del ítem, de 1 a 20 |
| 2 | Tipo de movimiento | `<TpoMov>` | 1 | ALFA | N | 1 | 1 | `D` (descuento) o `R` (recargo) |
| 3 | Glosa | `<GlosaDR>` | 45 | ALFA | I | 3 | 3 | Especificación del descuento o recargo |
| 4 | Tipo de valor | `<TpoValor>` | 1 | ALFA | I | 1 | 1 | `%` o `$` |
| 5 | Valor | `<ValorDR>` | 18 | NUM | I | 1 | 1 | Valor del descuento o recargo, 16 enteros y 2 decimales |
| 6 | Indicador exención | `<IndExeDR>` | 1 | NUM | N | 2 | 2 | Indica si el descuento/recargo afecta a ítems exentos o no afectos a IVA. `1`: exento o no afecto; `2`: no facturable |

### E. Datos de Referencia

Datos opcionales para referenciar otros documentos. Hasta **40 repeticiones**. Zona con obligatoriedad **3** en v4.2 (**4** en v2.22).

| # | Campo | Tag | Largo | Tipo | I | Oblig. | Descripción / Validación |
|---|---|---|---|---|---|---|---|
| 1 | N° de Línea o N° Secuencial | `<NroLinRef>` | 2 | NUM | N | 1 | Número de dato de referencia, de 1 a 40 |
| 2 | Tipo Documento de referencia | `<TpoDocRef>` | 3 | ALFA | N | 2 | Valores: `39` Boleta electrónica; `41` Boleta no afecta o exenta electrónica; `50` Guía de despacho; `52` Guía de despacho electrónica; `801` Orden de Compra; `802` Nota de pedido; `803` Contrato; `804` Resolución; `805` Proceso ChileCompra; `806` Ficha ChileCompra; `813` Pasaporte. Para documento tributario debe usarse valor numérico del rango indicado; si es alfabético no hay validación y puede usarse para referenciar documentos no tributarios distintos de los especificados |
| 3 | Folio de Referencia | `<FolioRef>` | 18 | ALFA | N | 2 | Folio del documento que se referencia. **Obligatorio si se informa `<TpoDocRef>`** |
| 4 | Código referencia | `<CodRef>` | 18 | ALFA | I | 3 | Código alfanumérico establecido por la empresa para informar el dato al cliente |
| 5 | Razón referencia | `<RazonRef>` | 90 | ALFA | I | 3 | Detalle del dato. Sin validación |
| 6 | Código Vendedor | `<CodVndor>` | 8 | ALFA | I | 3 | Código alfanumérico de la empresa para su vendedor. Puede estar asociado a "INTERNET" |
| 5* | Código Caja | `<CodCaja>` | 8 | ALFA | I | 3 | Código alfanumérico de la empresa para la caja. *(El PDF repite el número de fila "5"; error del original)* |

Los campos `<TpoDocRef>` y `<FolioRef>` se agregaron en el cambio 2020-07-20 (presentes en ambas versiones).

### F. Datos de Georreferenciación (solo v4.2, agregado 2023-06-01)

Datos opcionales para indicar georreferenciación. En la tabla de zonas figura con obligatoriedad 2, pero la sección los describe como "datos opcionales" y todos los campos son obligatoriedad 3.

| # | Campo | Tag | Largo | Tipo | I | Oblig. | Descripción / Validación |
|---|---|---|---|---|---|---|---|
| 1 | Latitud | `<LatitudEmision>` | 30 | ALFA | N | 3 | Latitud de la ubicación geográfica de emisión, estándar WGS84 en modalidad decimal |
| 2 | Longitud | `<LongitudEmision>` | 30 | ALFA | N | 3 | Longitud de la ubicación de emisión, WGS84 decimal |
| 3 | Sistema de Referencia | `<SistemaReferencia>` | 1 | NUM | N | 3 | Código del sistema de referencia. `1`: WGS84 |

### G. Timbre Electrónico SII del Documento (F en v2.22)

Firma electrónica sobre los campos representativos del DTE y el Código de Autorización de Folios (CAF) entregado por el SII. Corresponde a la información del **código de barras bidimensional PDF417**. Es el mismo formato de la factura. Para el detalle, ver Anexos del Instructivo de Generación de Documentos del SII. Tipo ALFA, columna I = N.

---

## 3. IndServicio y sus valores

Campo `<IndServicio>` (Encabezado, 1 NUM, obligatoriedad 1 en 39 y 41). "El objetivo del indicador es identificar el tipo de transacción":

| Valor | Significado |
|---|---|
| 1 | Boletas de servicios periódicos |
| 2 | Boletas de servicios periódicos domiciliarios |
| 3 | Boletas de venta y servicios |
| 4 | Boleta de Espectáculo emitida por cuenta de Terceros |

Condiciones asociadas al valor:

- `IndServicio = 1 o 2` → `<DirRecep>` obligatorio.
- `IndServicio = 2` (periódicos domiciliarios) → `<FchVenc>` obligatorio.
- `IndServicio = 1 o 2` → se usan `<PeriodoDesde>` / `<PeriodoHasta>`.
- `IndServicio = 3` con `RUTRecep = 0` → código interno obligatorio (condición asociada a nombre/código del receptor; ver nota de ambigüedad en la tabla del Encabezado).
- `IndServicio = 3` (no periódicos ni domiciliarios) → se permite RUT genérico `66.666.666-6` si no se cuenta con RUT ni código interno del cliente.
- `IndServicio = 4` → `<ItemEspectaculo>` obligatorio en el detalle; si `<ItemEspectaculo> = 01`, el área INFO TICKET es obligatoria.

Nota para emisión vía OpenFactura: para una venta común de mostrador el valor es `3`.

---

## 4. Reglas de montos: IVA incluido (regla exacta)

Regla central que distingue a la boleta de la factura:

> **En boletas los montos de las líneas de detalle son BRUTOS (con IVA incluido), salvo que el encabezado lleve `<IndMntNeto>` con valor `2`.**

Textualmente el formato lo establece campo por campo:

- `<PrcItem>` (Precio Unitario): "Este precio es bruto con IVA, excepto cuando el Indicador Montos Netos tiene el valor 2."
- `<DescuentoMonto>`: "Este monto es bruto con IVA, excepto cuando el Indicador Montos Netos tiene el valor 2."
- `<RecargoMonto>`: "Este monto es bruto con IVA, excepto cuando el Indicador Montos Netos tiene el valor 2."
- `<MontoItem>` (Valor por línea): "(Precio Unitario * Cantidad) - Monto Descuento + Monto Recargo. Este valor es bruto (con IVA), excepto cuando el campo Indicador Montos Netos tiene el valor 2."

Sobre `<IndMntNeto>`:

- Único valor definido: `2` = "Líneas de detalle indican montos netos, es decir no incluyen el IVA".
- Obligatoriedad **3 (opcional)** en boleta afecta y **0 (no aplica)** en boleta exenta. Si no se informa, rige el modo bruto/IVA incluido.

Fórmulas de los totalizadores del encabezado:

| Campo | Regla exacta |
|---|---|
| `<MntNeto>` | "Suma de valores totales de ítems afectos - descuentos + recargos (asignados a ítems afectos). **Si no está presente el Indicador de Montos Netos, el resultado anterior se debe dividir por (1 + tasa IVA)**". Solo válido si la boleta no es exenta. Valor > 0. Obligatoriedad 1 en boleta 39, 0 en 41 |
| `<IVA>` | "Sólo es válido si la boleta no es exenta. Igual a la tasa (%) de IVA aplicada al Monto neto" (es decir, IVA = MntNeto × tasa). Obligatoriedad 1 en 39, 0 en 41 |
| `<MntExe>` | Suma de Valor por línea de detalle para Indicador Exención = 1 |
| `<MntTotal>` | "Se calcula como Monto neto + IVA + Monto Exento" |
| `<MontoNF>` | Suma de montos con Indicador exención = 2 y 6 (v4.2). Puede ser negativo |
| `<TotalPeriodo>` | Monto Total + Monto no Facturable |
| `<VlrPagar>` | Valor total + Saldo anterior. Puede ser negativo o cero |

Implicación práctica para el SDK (emisión vía OpenFactura con los mismos nombres de campo): en una boleta 39 estándar sin `IndMntNeto`, se cargan precios y `MontoItem` **con IVA incluido**; `MntNeto` = suma bruta de ítems afectos (± descuentos/recargos globales asignados a afectos) **dividida por (1 + tasa IVA)** (redondeada a pesos), `IVA = MntTotal afecto − MntNeto` según la tasa, y `MntTotal = MntNeto + IVA + MntExe`. En una boleta 41 solo van `MntExe` y `MntTotal` (sin `MntNeto`, `IVA` ni `IndMntNeto`).

Otros formatos numéricos: `<QtyItem>` y `<PrcItem>` admiten 12 enteros y 6 decimales; `<DescuentoPct>`/`<RecargoPct>` 3 enteros y 2 decimales (0–100); `<ValorDR>` y los subtotales informativos, 16 enteros y 2 decimales.

---

## 5. Diferencias entre los dos PDFs (v2.22 2020 vs v4.2 2025)

Ambos son el documento de formato técnico; v4.2 acumula estos cambios posteriores a v2.22 (según su propia bitácora):

**Cambios 2022-12-28**
- Se renombra el tag `<MntoNF>` a `<MontoNF>`.
- Se complementa la descripción de Monto no Facturable (v4.2 suma IndExe = 2 **y 6**; v2.22 decía solo 2).

**Cambios 2023-06-01**
- Se agregan `<RutProvSW>` y `<RznSocProvSW>` (RUT y nombre del proveedor de software de boleta electrónica).
- Se agrega el apartado **F. Datos de Georreferenciación** (`<LatitudEmision>`, `<LongitudEmision>`, `<SistemaReferencia>`); el Timbre pasa a ser la letra G.

**Cambios 2024-06-01**
- Se **elimina el código de obligatoriedad 4** (solo impreso), reemplazado por 3 en: `<RznSocEmisor>`, `<GiroEmisor>`, `<CdgSIISucur>` *(así lo lista la bitácora, aunque en la tabla figura con 2)*, `<DirOrigen>`, `<CmnaOrigen>`, `<CiudadOrigen>`.
- En `<RznSocEmisor>` la columna I pasa de "I" a "N".

**Cambios 2024-12-31 (Ley 21.713)**
- Se agregan `<MedioPago>`, `<CorreoRecep>` y `<TelefonoRecep>` al Encabezado.
- Se modifica descripción y obligatoriedad de `<RutRecep>` y `<RznSocEmisor>` (umbral Monto Total > 135 UF para identificar al receptor).

**Cambios 2025-09-08**
- Se modifica descripción y obligatoriedad de `<CorreoRecep>` y `<TelefonoRecep>`.
- Se modifica la descripción de `<MedioPago>` y `<NmbItem>`.
- `<RznSocRecep>` y `<RznSocProvSW>` pasan a largo **100**.

**Otras diferencias estructurales**
- Zona "Datos de Referencia": obligatoriedad 4 en v2.22 → **3** en v4.2.
- v4.2 agrega la zona "Datos de Georreferenciación" (obligatoriedad 2 en la tabla de zonas).
- Umbral **135 UF (Ley 21.713)**: solo en v4.2 — afecta a `<MedioPago>` (obligatorio), `<RUTRecep>` (debe ser el RUT real del receptor), `<RznSocRecep>` (se debe imprimir), `<NmbItem>` (descripción clara) y a la condición de código interno del receptor.
- El resto del formato (zonas A–E, tags, largos, validaciones, límites de 1000 líneas de detalle, 20 subtotales, 20 descuentos/recargos, 40 referencias, 500 boletas por envío) es idéntico entre ambas versiones.

Para emisión nueva, **usar v4.2 como fuente de verdad**.

---

## 6. Representación impresa/timbre (lo relevante para emisión vía API)

Aunque OpenFactura genera la representación impresa, estos puntos del formato afectan qué datos deben ir en el JSON de emisión:

- La **columna I** define qué campos deben aparecer en la representación digital o impresa: `<TipoDTE>` se imprime **en palabras** (código P); se imprimen (I) `<Folio>`, `<FchEmis>`, `<RUTEmisor>`, `<IVA>` (en 39), `<MntTotal>`, `<DirRecep>` (si aplica), `<NmbItem>`, `<MontoItem>`, `<QtyItem>`, `<PrcItem>`, `<DscItem>`, montos de descuento/recargo por línea, los campos del área INFO TICKET, `<GlosaSTI>` y valores de subtotales, `<TpoValor>`/`<ValorDR>`/`<GlosaDR>`, `<CodRef>`/`<RazonRef>`/`<CodVndor>`/`<CodCaja>`, y `<PeriodoDesde>`/`<PeriodoHasta>`/`<FchVenc>` cuando se informan.
- `<RUTRecep>` **se imprime solo si es distinto de 0 y de 66.666.666-6**.
- v4.2: `<MedioPago>` es "obligatorio imprimir" cuando aplica (Monto total > 135 UF) y `<RznSocRecep>` "se debe imprimir" cuando Monto total > 135 UF.
- El **Timbre Electrónico** (obligatoriedad de zona 1) es la firma sobre los campos representativos del DTE más el CAF, representada como código de barras PDF417; mismo formato que la factura. Al emitir por API, OpenFactura lo genera con el CAF; el SDK no lo construye.
- Bajo el timbre debe ir la leyenda de verificación ("verifique en www.sii.cl", opcionalmente más la URL de consulta propia).
- Los subtotales informativos pueden imprimirse intercalados entre líneas de detalle o agrupados aparte; `<OrdenSTI>` controla el orden de impresión.

---

## 7. MedioPago (medios de pago)

Campo `<MedioPago>` — **existe solo en v4.2** (agregado por cambio 2024-12-31, descripción modificada 2025-09-08). Encabezado, fila 10.

- **Descripción**: "Indica el Medio de Pago utilizado. Obligatorio cuando Monto total > 135 UF (Ley 21.713) y obligatorio imprimir."
- **Largo**: 1. **Tipo**: NUM. **Columna I**: N (aunque la descripción dice "obligatorio imprimir" cuando aplica; contradicción presente en el original). **Obligatoriedad**: 2 (condicional) tanto en boleta 39 como 41.
- **Valores**:

| Valor | Medio de pago |
|---|---|
| 1 | Efectivo |
| 2 | Pago electrónico |
| 3 | Transferencia electrónica |
| 4 | Cheque |
| 5 | Otro |

Es la única mención de medios de pago en ambos documentos (v2.22 no contiene ninguna).

---

## Notas de fidelidad de la fuente

- Esta referencia se generó por extracción de texto de los PDFs; en las tablas originales algunas celdas se superponen en la extracción (p. ej. largos incrustados en el texto: "medido20" = "medidor" + largo 20). Los valores de largo/tipo/obligatoriedad se contrastaron entre ambas versiones y son consistentes; donde quedó ambigüedad se indicó en la propia tabla (nota en `<CdgIntRecep>`/`<RznSocRecep>`; discrepancia bitácora-tabla de `<CdgSIISucur>`; numeración repetida "5" en `<CodCaja>`).
- No se inventó ningún campo ni valor: todos los tags, largos, códigos y fórmulas provienen textualmente de los dos PDFs.
