# OpenFactura API — Emisión de DTE

Referencia definitiva del endpoint de emisión de Documentos Tributarios Electrónicos (DTE) de OpenFactura (Haulmer). Cubre la emisión estándar (`POST /v2/dte/document`) y la emisión de enlace de autoservicio (mismo endpoint, con `selfService`).

> Fuente: documentación oficial de OpenFactura (colección Postman). Las validaciones de esta API corresponden a las mismas del Servicio de Impuestos Internos (SII). Los nombres de campos son **sensibles a mayúsculas** y siguen la nomenclatura del SII:
> - [Formato de documentos electrónicos del SII](http://www.sii.cl/factura_electronica/factura_mercado/formato_dte.pdf)
> - [Formato boletas electrónicas del SII](http://www.sii.cl/factura_electronica/factura_mercado/boletas_elec_020.pdf)
> - [Formato de boleta electrónica (MedioPago)](https://www.sii.cl/factura_electronica/factura_mercado/formato_boleta_electronica.pdf)
>
> La documentación oficial presenta solo un **subconjunto** de los campos existentes (los más comunes). La lista completa de campos disponibles es la del formato de documentos electrónicos del SII; OpenFactura implementa cada uno de esos campos para los DTE soportados, en formato JSON con la misma convención de nombre y jerarquía.

---

## 1. Endpoint y headers

```
POST /v2/dte/document
```

| Ambiente | URL base |
|---|---|
| Producción | `https://api.haulmer.com` |
| Desarrollo | `https://dev-api.haulmer.com` |

### Headers HTTP

| Campo | Requerido | Tipo | Descripción |
|---|---|---|---|
| `apikey` | * | string | Verifica permisos sobre el endpoint e identifica quién realiza la petición. Siempre asociada a un usuario-empresa. |
| `Idempotency-Key` | | string | Llave de idempotencia generada por el cliente (ver §1.2). |
| `Content-Type` | * | string | `application/json` |

### 1.1 Rate limits

- Límite de consultas por segundo: **3**
- Límite de consultas por minuto: **100**

Al superar cualquiera de estos límites, la API responde HTTP **429**:

```json
{ "statusCode": 429, "message": "Rate limit is exceeded. Try again in X seconds." }
```

(En los ejemplos de la doc de emisión también aparece la variante `{"message": "API rate limit exceeded"}`.)

Error de validación de API Key → HTTP **401**:

```json
{ "statusCode": 401, "message": "Access denied due to invalid subscription key. Make sure to provide a valid key for an active subscription." }
```

Credenciales inválidas en el endpoint de emisión → HTTP **403**:

```json
{ "message": "Invalid authentication credentials" }
```

### 1.2 Idempotencia (`Idempotency-Key`)

Las emisiones soportan idempotencia: permite el **reenvío seguro** de peticiones sin realizar accidentalmente la misma emisión dos veces.

- La llave debe ser **única y generada por el cliente**.
- Duración: **24 horas**. Si dentro de ese tiempo se reenvía la misma key, se obtiene un error de validación de Idempotency Key (`OF-06`).
- Cuando se genera un error de Idempotency Key, la API **devuelve el `token`** que fue asignado a ese documento (ver ejemplo OF-06 en §7.3), lo que permite recuperar el DTE ya emitido.
- Ventaja principal: ante un fallo en la transmisión, recepción y/o tratamiento de la respuesta, se puede reintentar de forma segura (dentro de 24 horas) porque siempre se emitirá una sola vez.

### 1.3 Ambiente de desarrollo — empresas de prueba

El ambiente de desarrollo es completamente operativo y no requiere cuenta. Las emisiones usan un **CAF simulado**, por lo que el timbre no puede ser validado. Hay dos empresas de prueba, cada una con su API Key pública; estos datos deben enviarse en la sección `Emisor` durante cada emisión:

**Haulmer**

```json
{
    "apikey": "928e15a2d14d4a6292345f04960f4bd3",
    "RUTEmisor": "76795561-8",
    "RznSoc": "HAULMER SPA",
    "GiroEmis": "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
    "Acteco": 479100,
    "DirOrigen": "ARTURO PRAT 527   CURICO",
    "CmnaOrigen": "Curicó",
    "CdgSIISucur": "81303347"
}
```

**Hosty**

```json
{
    "apikey": "41eb78998d444dbaa4922c410ef14057",
    "RUTEmisor": "76430498-5",
    "RznSoc": "HOSTY SPA",
    "GiroEmis": "EMPRESAS DE SERVICIOS INTEGRALES DE INFORMÁTICA",
    "Acteco": 620200,
    "DirOrigen": "ARTURO PRAT 527 3 pis OF 1",
    "CmnaOrigen": "Curicó",
    "CdgSIISucur": "79457965"
}
```

---

## 2. Estructura top-level del request (Body)

| Campo | Requerido | Tipo | Descripción |
|---|---|---|---|
| `dte` | * | object | El DTE a emitir, con nomenclatura SII (ver §3). |
| `response` | | array | Formatos de respuesta deseados tras emisión exitosa (ver §2.1). Si no se envía, se devuelve solo el `TOKEN`. |
| `custom` | | object | Campos personalizados para el PDF (ver §2.2). |
| `ivaExceptional` | | array | IVA para artesanos (ver §2.3). |
| `sendEmail` | | object | Envío automático de email (ver §2.4). |

Para la variante de **enlace de autoservicio** se agregan `customer`, `customizePage` y `selfService` (este último requerido en esa variante) — ver §8.

### 2.1 `response[]` — formatos de respuesta

Corresponde a las respuestas que se desea recibir luego de una emisión exitosa. Es un arreglo con todas sus variables **en mayúsculas**. Si no se envía, se devuelve solamente un *token* (respuesta por defecto).

| Nodo Padre | Campo | Req. | Tipo |
|---|---|---|---|
| response | `XML` | | string |
| response | `PDF` | | string |
| response | `TIMBRE` | | string |
| response | `LOGO` | | string |
| response | `FOLIO` | | string |
| response | `RESOLUCION` | | string |
| response | `LETTER` | | string |
| response | `80MM` | | string |
| response | `80MMNOLOGO` | | string |

```json
{
  "response": ["XML", "PDF", "TIMBRE", "LOGO", "FOLIO", "RESOLUCION", "80MM"]
}
```

Significado de cada valor:

- **`XML`** — El documento generado para la emisión y enviado al SII, codificado en Base64. ⚠️ Al decodificar, considerar que el XML está en norma **ISO 8859-1** (no UTF-8).
- **`PDF`** — Documento emitido en PDF con la plantilla de OpenFactura, codificado en Base64. Para el SII solo es posible generar un documento con largo máximo de **1 página**; esta restricción aplica **solo al formato carta (`LETTER`)**. ⚠️ Si no se desea esta funcionalidad, se puede generar un PDF propio, siendo responsable de cumplir los requisitos que exige el SII.
- **`TIMBRE`** — Imagen del timbre generado al emitir el documento, formato PNG codificado en Base64.
- **`LOGO`** — Logo de la empresa registrada en OpenFactura, PNG codificado en Base64.
- **`FOLIO`** — Folio utilizado para la emisión.
- **`RESOLUCION`** — Fecha y número de resolución del tipo de documento emitido. Útil para generar la representación en PDF propia.
- **`LETTER`** y **`80MM`** — Formatos disponibles para la generación del PDF. Por defecto siempre se asume tamaño carta (`LETTER`).
- **`80MMNOLOGO`** — Formato de 80 mm para el PDF pero **sin el logo** de la empresa.
- **`SELF_SERVICE`** — Solo en emisión de enlace de autoservicio: devuelve la URL del enlace (ver §8).

### 2.2 `custom` — campos personalizados

Dos campos opcionales para personalizar la emisión; se ven reflejados en el PDF del documento. Se agregan a la raíz del JSON dentro del objeto `custom`:

| Nodo Padre | Campo | Req. | Tipo |
|---|---|---|---|
| custom | `informationNote` | | string |
| custom | `paymentNote` | | string |

### 2.3 `ivaExceptional` — Emisión de IVA para Artesanos

Para utilizar la funcionalidad de **IVA Artesano**, se agrega el campo `ivaExceptional` al mismo nivel de `dte`/`response`. Restricciones:

- Solo puede ser utilizada por contribuyentes cuya **actividad económica** sea **477396**.
- En la emisión de la boleta, el `IVA` en `Totales` se debe **enviar en 0**.
- La emisión tiene una **restricción de monto mensual equivalente a 5 UTM**. Si se supera este límite, la API responde con error **`OF-10`**.

```json
{
  "response": ["..."],
  "ivaExceptional": ["ARTESANO"],
  "dte": { }
}
```

### 2.4 `sendEmail` — envío automático de email

Opcionalmente se puede indicar un email para que la emisión del DTE sea enviada a esa casilla. Este correo es **adicional** al envío que se hace siempre por sistema al correo de intercambio. El email se envía **luego de ser aceptado por el SII**.

| Nodo Padre | Campo | Ejemplo | Descripción |
|---|---|---|---|
| sendEmail | `to` | `correo1@ejemplo.com` | Casilla de correo donde se mandará email. |
| sendEmail | `CC` | `cc1@ejemplo.com,cc2@ejemplo.com` | Copia del correo; múltiples casillas separadas por comas ",". |
| sendEmail | `BCC` | `bcc1@ejemplo.com,bcc2@ejemplo.com` | Copia oculta; múltiples casillas separadas por comas ",". |

```json
{
  "sendEmail": {
    "to": "correo1@ejemplo.com",
    "CC": "cc1@ejemplo.com,cc2@ejemplo.com",
    "BCC": "bcc1@ejemplo.com,bcc2@ejemplo.com"
  }
}
```

---

## 3. Estructura del objeto `dte`

El objeto `dte` debe contener todos los campos relacionados con el DTE que se desea emitir, basado en la nomenclatura del SII. El **orden de las secciones** (`Encabezado`, `Detalle`, `DscRcgGlobal`, etc.) debe respetarse tal como se detalla a continuación, así como su obligatoriedad. La exigencia de los campos **puede variar según el tipo de DTE** (ver formato SII).

### 3.1 Estructura de `dte`

| Nodo Padre | Campo | Req. | Tipo |
|---|---|---|---|
| dte | `Encabezado` | * | object |
| dte | `Detalle` | * | array |
| dte | `DscRcgGlobal` | | array |
| dte | `Referencia` | | array |
| dte | `Comisiones` | | array |

### 3.2 `Encabezado`

| Nodo Padre | Campo | Req. | Tipo |
|---|---|---|---|
| Encabezado | `IdDoc` | * | object |
| Encabezado | `Emisor` | * | object |
| Encabezado | `RUTMandante` | | string |
| Encabezado | `Receptor` | * | object |
| Encabezado | `RUTSolicita` | | string |
| Encabezado | `Transporte` | | object |
| Encabezado | `Totales` | * | object |

### 3.3 `IdDoc`

| Nodo Padre | Campo | Req. | Tipo | Regla |
|---|---|---|---|---|
| IdDoc | `TipoDTE` | * | int | Código del tipo de DTE (33, 34, 39, 41, 43, 52, 56, 61, …). |
| IdDoc | `Folio` | * | int | **Debe ser 0** (el folio real lo asigna OpenFactura y se retorna en `FOLIO`). |
| IdDoc | `FchEmis` | * | string | Formato `AAAA-MM-DD`. |
| IdDoc | `TpoTranCompra` | | int | |
| IdDoc | `TpoTranVenta` | | int | |
| IdDoc | `FmaPago` | | int | |
| IdDoc | `MedioPago` | | int | **Es obligatorio (aplica para Boletas) cuando el Monto total > 135 UF.** Ver [formato de boleta electrónica del SII](https://www.sii.cl/factura_electronica/factura_mercado/formato_boleta_electronica.pdf). |

Otros campos de `IdDoc` observados en los ejemplos oficiales (definidos en el formato SII):

| Campo | Tipo (observado) | Uso |
|---|---|---|
| `IndServicio` | string/int | Boletas (39/41). En los ejemplos: `"3"`. |
| `TipoDespacho` | string/int | Guía de Despacho (52). En el ejemplo: `"2"`. |
| `IndTraslado` | string/int | Guía de Despacho (52). En el ejemplo: `"3"`. |

### 3.4 `Emisor`

| Nodo Padre | Campo | Req. | Tipo |
|---|---|---|---|
| Emisor | `RUTEmisor` | * | string |
| Emisor | `RznSoc` | * | string |
| Emisor | `GiroEmis` | * | string |
| Emisor | `CorreoEmisor` | | string |
| Emisor | `Acteco` | * | int |
| Emisor | `DirOrigen` | * | string |
| Emisor | `CmnaOrigen` | * | string |

Notas y campos adicionales observados en los ejemplos oficiales:

- `CdgSIISucur` (string) — código SII de sucursal; aparece en todos los ejemplos de emisor.
- `Telefono` (string) — aparece en varios ejemplos.
- **En boletas (39/41)** el emisor usa los nombres **`RznSocEmisor`** y **`GiroEmisor`** en lugar de `RznSoc` y `GiroEmis`, y **omite `Acteco`** (nomenclatura del formato de boletas del SII).
- **En Guía de Despacho (52)** el ejemplo incluye dentro de `Emisor` el objeto `GuiaExport` con `CdgTraslado` (ej.: `"GuiaExport": { "CdgTraslado": "3" }`).

### 3.5 `Receptor`

| Nodo Padre | Campo | Req. | Tipo | Regla |
|---|---|---|---|---|
| Receptor | `RUTRecep` | * | string | |
| Receptor | `RznSocRecep` | * | string | **Es obligatorio cuando el monto total > 135 UF** (regla modificada el 10/02/2026). |
| Receptor | `GiroRecep` | * | string | |
| Receptor | `Contacto` | * | string | |
| Receptor | `DirRecep` | * | string | |
| Receptor | `CmnaRecep` | * | string | |

Notas:

- La tabla oficial marca estos campos como requeridos para documentos tributarios tipo factura; sin embargo, la exigencia varía por tipo de DTE. En **boletas (39/41)** los ejemplos oficiales solo envían `RUTRecep` (con el RUT genérico `66666666-6` para consumidor final).
- Varios ejemplos oficiales de facturas omiten `Contacto` y son aceptados; tratarlo como recomendado más que estrictamente obligatorio (ver §9, inconsistencias).

### 3.6 `Transporte` (opcional; usado en Guía de Despacho)

Campos observados en el ejemplo oficial de DTE 52:

| Nodo Padre | Campo | Tipo |
|---|---|---|
| Transporte | `DirDest` | string |
| Transporte | `CmnaDest` | string |
| Transporte | `CiudadDest` | string |

(El formato SII define campos adicionales de transporte — patente, RUT transportista, chofer, etc. — que la API acepta con la misma nomenclatura.)

### 3.7 `Detalle` (array de líneas)

| Nodo Padre | Campo | Req. | Tipo | Regla |
|---|---|---|---|---|
| Detalle | `NroLinDet` | * | int | Número secuencial de la línea. |
| Detalle | `NmbItem` | * | string | |
| Detalle | `DscItem` | | string | |
| Detalle | `QtyItem` | * | float | Máx **6 decimales**. |
| Detalle | `PrcItem` | * | float | Máx **6 decimales**. |
| Detalle | `MontoItem` | * | int | |
| Detalle | `IndExe` | | int | Si el producto es exento o no afecto. |

Campo adicional observado en el ejemplo de Liquidación Factura (43):

| Campo | Tipo (observado) | Uso |
|---|---|---|
| `TpoDocLiq` | string | Tipo de documento que se liquida en la línea (ej.: `"33"`). Solo DTE 43. |

### 3.8 `DscRcgGlobal` (opcional) — descuentos/recargos globales

| Nodo Padre | Campo | Req. | Tipo | Regla |
|---|---|---|---|---|
| DscRcgGlobal | `NroLinDR` | * | int | Número secuencial de la línea. |
| DscRcgGlobal | `TpoMov` | * | string | `D` (descuento) o `R` (recargo). |
| DscRcgGlobal | `GlosaDR` | | string | |
| DscRcgGlobal | `TpoValor` | * | string | `"%"` o `"$"`. |
| DscRcgGlobal | `ValorDR` | * | int | |
| DscRcgGlobal | `IndExeDR` | | int | `1` (No afecto o exento) o `2` (No facturable). |

### 3.9 `Referencia` (opcional; obligatoria en NC/ND)

La tabla de campos no aparece en la doc de emisión, pero los ejemplos oficiales de Nota de Crédito (61) y Nota de Débito (56) usan la siguiente estructura (nomenclatura SII):

| Campo | Tipo (observado) | Descripción |
|---|---|---|
| `NroLinRef` | int | Número secuencial de la referencia. |
| `TpoDocRef` | string | Tipo del documento referenciado (ej.: `"33"`). |
| `FolioRef` | string | Folio del documento referenciado. |
| `FchRef` | string | Fecha del documento referenciado, `AAAA-MM-DD`. |
| `CodRef` | string | Código de referencia SII (ej.: `"3"` en los ejemplos de NC/ND). |

```json
"Referencia": [
  { "NroLinRef": 1, "TpoDocRef": "33", "FolioRef": "106", "FchRef": "2018-08-16", "CodRef": "3" }
]
```

### 3.10 `Comisiones` (opcional)

Declarada en la estructura de `dte` como array; sus campos internos no se detallan en la doc de emisión (usar nomenclatura SII para Liquidaciones Factura).

### 3.11 `Totales`

| Nodo Padre | Campo | Req. | Tipo |
|---|---|---|---|
| Totales | `MntNeto` | | int |
| Totales | `MntExe` | | int |
| Totales | `IVA` | | int |
| Totales | `MntTotal` | * | int |
| Totales | `MntNF` | | int |
| Totales | `SaldoAnterior` | | int |
| Totales | `VlrPagar` | | int |

Campos adicionales observados en los ejemplos oficiales:

| Campo | Tipo (observado) | Uso |
|---|---|---|
| `TasaIVA` | string | Enviada como `"19"` en todos los ejemplos afectos. |
| `MontoPeriodo` | int | Facturas/NC/ND/Guías en los ejemplos. |
| `TotalPeriodo` | int | Boletas (39/41) en los ejemplos. |

Coherencia aritmética: la API valida los montos (`MntNeto`, `IVA`, `MntTotal`) contra el `Detalle` y `DscRcgGlobal`; una descuadratura produce error `OF-10` con `details` por campo (ver §7).

---

## 4. Particularidades por tipo de DTE

Tipos con ejemplo oficial en la doc de emisión: **33, 34, 39, 41, 43, 52, 56, 61**. (Otros tipos soportados por OpenFactura — p. ej. 46, 110, 111, 112 — siguen el formato SII, pero no tienen ejemplo ni reglas específicas en esta fuente.)

### 4.1 Factura Electrónica (33)

- `Totales` afectos: `MntNeto`, `TasaIVA`, `IVA`, `MntTotal` (+ opcionales `MontoPeriodo`, `VlrPagar`).
- `IdDoc` típico: `TpoTranCompra`, `TpoTranVenta`, `FmaPago`.
- Receptor completo (`RUTRecep`, `RznSocRecep`, `GiroRecep`, `DirRecep`, `CmnaRecep`, `Contacto`).

### 4.2 Factura Exenta (34)

- Sin `MntNeto`/`IVA`: usar `MntExe` y `MntTotal` (iguales si todo es exento).
- Cada línea exenta del `Detalle` lleva `IndExe: 1`.

### 4.3 Boleta Electrónica (39) y Boleta Exenta (41)

- Emisor con nomenclatura de boletas: **`RznSocEmisor`** y **`GiroEmisor`** (no `RznSoc`/`GiroEmis`), sin `Acteco`.
- `IdDoc` con `IndServicio` (`"3"` en los ejemplos). No llevan `FmaPago` en los ejemplos.
- `Receptor` mínimo: solo `RUTRecep` (RUT genérico `66666666-6` para consumidor final).
- **`RznSocRecep` es obligatorio cuando el monto total > 135 UF** (regla 10/02/2026).
- **`MedioPago` (IdDoc) es obligatorio para boletas cuando el Monto total > 135 UF** (agregado 10/02/2026). Valores según el formato de boleta electrónica del SII.
- `Totales` de boleta afecta (39): `MntNeto`, `IVA`, `MntTotal`, `TotalPeriodo`, `VlrPagar` (sin `TasaIVA` en el ejemplo; el neto se calcula "hacia atrás" desde el total: ej. 840 + 160 = 1000).
- Boleta exenta (41): `MntExe`, `MntTotal`, `TotalPeriodo`, `VlrPagar`; líneas con `IndExe: 1`.
- IVA Artesano (`ivaExceptional: ["ARTESANO"]`): boletas con `IVA: 0`, solo Acteco 477396, tope mensual 5 UTM (ver §2.3).
- El código `OF-23` puede bloquear temporalmente la emisión de boletas (ver §7.1).

### 4.4 Liquidación Factura (43)

- Igual a factura afecta en `Totales`.
- Cada línea del `Detalle` lleva **`TpoDocLiq`** con el tipo de documento liquidado (ej.: `"33"`).
- La sección `Comisiones` está disponible en la estructura de `dte`.

### 4.5 Guía de Despacho (52)

- `IdDoc` con **`TipoDespacho`** y **`IndTraslado`** (en el ejemplo: `"2"` y `"3"`).
- `Emisor` puede incluir **`GuiaExport`** con `CdgTraslado`.
- `Encabezado.Transporte` con `DirDest`, `CmnaDest`, `CiudadDest`.
- `Totales` como factura afecta (`MntNeto`, `TasaIVA`, `IVA`, `MntTotal`).
- **Resolución 154/2025** (changelog 28/05/2026): se actualizó el soporte de Guías de Despacho según esta resolución. Los nuevos campos son **actualmente opcionales, pero retornan `WARNING` si no son enviados y serán obligatorios próximamente**. (La fuente no detalla la lista de campos nuevos; consultar el formato SII actualizado.)
- Para anular una guía existe el endpoint separado `anular DTE 52` (fuera del alcance de este documento).

### 4.6 Nota de Débito (56) y Nota de Crédito (61)

- Requieren la sección **`Referencia`** apuntando al documento que corrigen: `NroLinRef`, `TpoDocRef`, `FolioRef`, `FchRef`, `CodRef` (en los ejemplos `CodRef: "3"`).
- `Totales` como el documento referenciado (afecto en los ejemplos).
- En autoservicio, la conversión de boleta a factura **gatilla internamente la anulación de la boleta con una nota de crédito** (ver §8.5).

---

## 5. Respuesta exitosa

Existen dos tipos de respuestas: emisión exitosa (documento emitido correctamente) y emisión fallida (errores en el `dte` enviado, ver §7).

En todas las respuestas validadas correctamente por OpenFactura se incorpora el campo **`TOKEN`**, útil para hacer seguimiento al DTE generado (endpoint `document/token/{value}`). Excepcionalmente se podría devolver el campo **`WARNING`**, que indica reparos que **no impiden la emisión** pero que se sugiere corregir en siguientes emisiones (p. ej., omitir los nuevos campos de la Res. 154/2025 en guías).

| Campo | Opcional | Tipo | Descripción |
|---|---|---|---|
| `TOKEN` | | string | Token de seguimiento. Siempre presente. |
| `WARNING` | * | string | Reparos en el envío. |
| `XML` | * | string | XML en Base64 con codificación **ISO 8859-1** (considerar al decodificar). |
| `PDF` | * | string | Representación en Base64 del PDF. |
| `TIMBRE` | * | string | Imagen PNG en Base64. |
| `LOGO` | * | string | Imagen PNG en Base64. |
| `FOLIO` | * | int | Folio asignado por el SII. |
| `RESOLUCION` | * | object | Fecha y número de resolución: `{ "fecha": string, "numero": int }`. |
| `SELF_SERVICE` | * | string | URL del enlace de autoservicio (solo en esa variante, ver §8). |

Los campos opcionales aparecen solo si fueron solicitados en `response[]`.

**Forma general:**

```json
{
    "TOKEN": "string",
    "FOLIO": 109,
    "RESOLUCION": { "fecha": "2018-03-26", "numero": 0 },
    "TIMBRE": "<PNG base64>",
    "XML": "<XML ISO-8859-1 base64>",
    "LOGO": "<PNG base64>",
    "PDF": "<PDF base64>"
}
```

**Ejemplo real mínimo** (request con `"response": ["PDF", "FOLIO"]`):

```json
{
    "TOKEN": "b822a58da11856bb09423a0a6fba59f5e089bd738e01d3ea670c45d4686f66d6",
    "FOLIO": 3130,
    "PDF": "<PDF base64>"
}
```

**Ejemplo real completo** (request con `"response": ["XML","PDF","TIMBRE","LOGO","FOLIO","RESOLUCION"]`; los valores Base64 vienen truncados en esta referencia porque son binarios de gran tamaño — el TIMBRE/LOGO son PNG, el XML ~14 KB y el PDF ~190 KB en Base64):

```json
{
    "TOKEN": "b3cfd2d2ea9cb6d38fa7d6f3df3c2d43eb13598aacb83c0da9580d6de629da95",
    "FOLIO": 109,
    "RESOLUCION": { "fecha": "2018-03-26", "numero": 0 },
    "TIMBRE": "iVBORw0KGgo...[base64 PNG truncado]...",
    "XML": "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iSVNPLTg4NTktMSI/...[base64 truncado]...",
    "LOGO": "iVBORw0KGgo...[base64 PNG truncado]...",
    "PDF": "JVBERi0xLjQK...[base64 PDF truncado]..."
}
```

Los 8 ejemplos de emisión exitosa de la doc oficial (Factura 33, Guía 52, Factura Exenta 34, Liquidación 43, NC 61, Boleta Exenta 41, Boleta 39, ND 56) devuelven exactamente esta misma estructura; solo varía el request. Los 4 ejemplos restantes son de error: OF-10 (400), OF-06 (400), 403 y 429 — ver §7.

---

## 6. Ejemplos de request por caso de uso

Todos son requests oficiales de la doc, reformateados. `Folio` siempre en `0`; `FchEmis` con la fecha de emisión real.

### 6.1 Factura Electrónica (33)

```json
{
  "response": ["PDF", "FOLIO"],
  "dte": {
    "Encabezado": {
      "IdDoc": {
        "TipoDTE": 33,
        "Folio": 0,
        "FchEmis": "2026-02-10",
        "TpoTranCompra": "1",
        "TpoTranVenta": "1",
        "FmaPago": "2"
      },
      "Emisor": {
        "RUTEmisor": "76795561-8",
        "RznSoc": "HAULMER SPA",
        "GiroEmis": "VENTA AL POR MENOR POR CORREO, POR INTERNET Y VIA TELEFONICA",
        "Acteco": "479100",
        "DirOrigen": "ARTURO PRAT 527   CURICO",
        "CmnaOrigen": "Curicó",
        "Telefono": "0 0",
        "CdgSIISucur": "81303347"
      },
      "Receptor": {
        "RUTRecep": "76430498-5",
        "RznSocRecep": "HOSTY SPA",
        "GiroRecep": "ACTIVIDADES DE CONSULTORIA DE INFORMATIC",
        "DirRecep": "ARTURO PRAT 527 3 pis OF 1",
        "CmnaRecep": "Curicó"
      },
      "Totales": {
        "MntNeto": 2000,
        "TasaIVA": "19",
        "IVA": 380,
        "MntTotal": 2380,
        "MontoPeriodo": 2380,
        "VlrPagar": 2380
      }
    },
    "Detalle": [
      { "NroLinDet": 1, "NmbItem": "item", "QtyItem": 1, "PrcItem": 2000, "MontoItem": 2000 }
    ]
  }
}
```

### 6.2 Factura Exenta (34)

```json
{
  "response": ["XML", "PDF", "TIMBRE", "LOGO", "FOLIO", "RESOLUCION"],
  "dte": {
    "Encabezado": {
      "IdDoc": { "TipoDTE": 34, "Folio": 0, "FchEmis": "2026-02-10", "FmaPago": "2" },
      "Emisor": {
        "RUTEmisor": "76795561-8",
        "RznSoc": "HAULMER SPA",
        "GiroEmis": "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
        "Acteco": 479100,
        "DirOrigen": "ARTURO PRAT 527 CURICO",
        "CmnaOrigen": "Curicó",
        "Telefono": "00",
        "CdgSIISucur": "81303347"
      },
      "Receptor": {
        "RUTRecep": "76430498-5",
        "RznSocRecep": "HOSTY SPA",
        "GiroRecep": "EMPRESAS DE SERVICIOS INTEGRALES DE INFO",
        "Contacto": "+56969195057",
        "DirRecep": "Arturo Prat 527 3 piso oficina 1",
        "CmnaRecep": "CURICÓ"
      },
      "Totales": { "MntExe": 2000, "MntTotal": 2000, "MontoPeriodo": 2000, "VlrPagar": 2000 }
    },
    "Detalle": [
      { "NroLinDet": 1, "NmbItem": "item exento", "QtyItem": 1, "PrcItem": 2000, "IndExe": 1, "MontoItem": 2000 }
    ]
  }
}
```

### 6.3 Boleta Electrónica (39)

```json
{
  "response": ["XML", "PDF", "TIMBRE", "LOGO", "FOLIO", "RESOLUCION"],
  "dte": {
    "Encabezado": {
      "IdDoc": { "TipoDTE": 39, "Folio": 0, "FchEmis": "2026-02-10", "IndServicio": "3" },
      "Emisor": {
        "RUTEmisor": "76795561-8",
        "RznSocEmisor": "HAULMER SPA",
        "GiroEmisor": "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET",
        "CdgSIISucur": "81303347",
        "DirOrigen": "ARTURO PRAT 527 CURICO",
        "CmnaOrigen": "Curicó"
      },
      "Receptor": { "RUTRecep": "66666666-6" },
      "Totales": { "MntNeto": 840, "IVA": 160, "MntTotal": 1000, "TotalPeriodo": 1000, "VlrPagar": 1000 }
    },
    "Detalle": [
      { "NroLinDet": 1, "NmbItem": "Item 1", "QtyItem": 1, "PrcItem": 1000, "MontoItem": 1000 }
    ]
  }
}
```

Nota: si `MntTotal` > 135 UF, agregar `MedioPago` en `IdDoc` y `RznSocRecep` en `Receptor`.

### 6.4 Boleta Exenta (41)

```json
{
  "response": ["XML", "PDF", "TIMBRE", "LOGO", "FOLIO", "RESOLUCION"],
  "dte": {
    "Encabezado": {
      "IdDoc": { "TipoDTE": 41, "Folio": 0, "FchEmis": "2026-02-10", "IndServicio": "3" },
      "Emisor": {
        "RUTEmisor": "76795561-8",
        "RznSocEmisor": "HAULMER SPA",
        "GiroEmisor": "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
        "CdgSIISucur": "81303347",
        "DirOrigen": "ARTURO PRAT 527 CURICO",
        "CmnaOrigen": "Curicó"
      },
      "Receptor": { "RUTRecep": "66666666-6" },
      "Totales": { "MntExe": 2000, "MntTotal": 2000, "TotalPeriodo": 2000, "VlrPagar": 2000 }
    },
    "Detalle": [
      { "NroLinDet": 1, "IndExe": 1, "NmbItem": "Item exento", "QtyItem": 1, "PrcItem": 2000, "MontoItem": 2000 }
    ]
  }
}
```

### 6.5 Liquidación Factura (43)

```json
{
  "response": ["XML", "PDF", "TIMBRE", "LOGO", "FOLIO", "RESOLUCION"],
  "dte": {
    "Encabezado": {
      "IdDoc": { "TipoDTE": 43, "Folio": 0, "FchEmis": "2026-02-10", "TpoTranCompra": "1", "TpoTranVenta": "1", "FmaPago": "2" },
      "Emisor": {
        "RUTEmisor": "76795561-8",
        "RznSoc": "HAULMER SPA",
        "GiroEmis": "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
        "Acteco": 479100,
        "DirOrigen": "ARTURO PRAT 527 CURICO",
        "CmnaOrigen": "Curicó",
        "Telefono": "00",
        "CdgSIISucur": "81303347"
      },
      "Receptor": {
        "RUTRecep": "76430498-5",
        "RznSocRecep": "HOSTY SPA",
        "GiroRecep": "EMPRESAS DE SERVICIOS INTEGRALES DE INFO",
        "DirRecep": "ARTURO PRAT 527 3 pis OF 1",
        "CmnaRecep": "Curicó",
        "Contacto": "null"
      },
      "Totales": { "MntNeto": 2000, "TasaIVA": "19", "IVA": 380, "MntTotal": 2380, "MontoPeriodo": 2380, "VlrPagar": 2380 }
    },
    "Detalle": [
      { "NroLinDet": 1, "TpoDocLiq": "33", "NmbItem": "item", "QtyItem": 1, "PrcItem": 2000, "MontoItem": 2000 }
    ]
  }
}
```

### 6.6 Guía de Despacho (52)

```json
{
  "response": ["XML", "PDF", "TIMBRE", "LOGO", "FOLIO", "RESOLUCION"],
  "dte": {
    "Encabezado": {
      "IdDoc": {
        "TipoDTE": 52,
        "Folio": 0,
        "FchEmis": "2026-02-10",
        "TipoDespacho": "2",
        "IndTraslado": "3",
        "TpoTranVenta": "1",
        "FmaPago": "1"
      },
      "Emisor": {
        "RUTEmisor": "76795561-8",
        "RznSoc": "HAULMER SPA",
        "GiroEmis": "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
        "Acteco": 479100,
        "GuiaExport": { "CdgTraslado": "3" },
        "DirOrigen": "ARTURO PRAT 527 CURICO",
        "CmnaOrigen": "Curicó",
        "CdgSIISucur": "81303347"
      },
      "Receptor": {
        "RUTRecep": "76430498-5",
        "RznSocRecep": "HOSTY SPA",
        "GiroRecep": "EMPRESAS DE SERVICIOS INTEGRALES DE INFO",
        "DirRecep": "ARTURO PRAT 527 3 pis OF 1",
        "CmnaRecep": "Curicó"
      },
      "Transporte": { "DirDest": "Arturo Prat 527", "CmnaDest": "Curicó", "CiudadDest": "Curicó" },
      "Totales": { "MntNeto": 2000, "TasaIVA": "19", "IVA": 380, "MntTotal": 2380, "MontoPeriodo": 2380, "VlrPagar": 2380 }
    },
    "Detalle": [
      { "NroLinDet": 1, "NmbItem": "item despacho", "QtyItem": 1, "PrcItem": 2000, "MontoItem": 2000 }
    ]
  }
}
```

### 6.7 Nota de Débito (56)

```json
{
  "response": ["XML", "PDF", "TIMBRE", "LOGO", "FOLIO", "RESOLUCION"],
  "dte": {
    "Encabezado": {
      "IdDoc": { "TipoDTE": 56, "Folio": 0, "FchEmis": "2026-02-10", "FmaPago": "2" },
      "Emisor": {
        "RUTEmisor": "76795561-8",
        "RznSoc": "HAULMER SPA",
        "GiroEmis": "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
        "Acteco": 479100,
        "DirOrigen": "ARTURO PRAT 527 CURICO",
        "CmnaOrigen": "Curicó",
        "CdgSIISucur": "81303347"
      },
      "Receptor": {
        "RUTRecep": "76430498-5",
        "RznSocRecep": "HOSTY SPA",
        "GiroRecep": "EMPRESAS DE SERVICIOS INTEGRALES DE INFO",
        "Contacto": "+56969195057",
        "DirRecep": "Arturo Prat 527 3 piso oficina 1",
        "CmnaRecep": "CURICÓ"
      },
      "Totales": { "MntNeto": 2000, "TasaIVA": "19", "IVA": 380, "MntTotal": 2380, "MontoPeriodo": 2380, "VlrPagar": 2380 }
    },
    "Detalle": [
      { "NroLinDet": 1, "NmbItem": "item", "QtyItem": 1, "PrcItem": 2000, "MontoItem": 2000 }
    ],
    "Referencia": [
      { "NroLinRef": 1, "TpoDocRef": "33", "FolioRef": "109", "FchRef": "2018-08-16", "CodRef": "3" }
    ]
  }
}
```

### 6.8 Nota de Crédito (61)

```json
{
  "response": ["XML", "PDF", "TIMBRE", "LOGO", "FOLIO", "RESOLUCION"],
  "dte": {
    "Encabezado": {
      "IdDoc": { "TipoDTE": 61, "Folio": 0, "FchEmis": "2026-02-10", "TpoTranVenta": "1", "FmaPago": "2" },
      "Emisor": {
        "RUTEmisor": "76795561-8",
        "RznSoc": "HAULMER SPA",
        "GiroEmis": "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
        "Acteco": 479100,
        "DirOrigen": "ARTURO PRAT 527 CURICO",
        "CmnaOrigen": "Curicó",
        "Telefono": "00",
        "CdgSIISucur": "81303347"
      },
      "Receptor": {
        "RUTRecep": "76430498-5",
        "RznSocRecep": "HOSTY SPA",
        "GiroRecep": "EMPRESAS DE SERVICIOS INTEGRALES DE INFO",
        "Contacto": "+56969195057",
        "DirRecep": "Arturo Prat 527 3 piso oficina 1",
        "CmnaRecep": "CURICÓ"
      },
      "Totales": { "MntNeto": 1500, "TasaIVA": "19", "IVA": 285, "MntTotal": 1785, "MontoPeriodo": 1785, "VlrPagar": 1785 }
    },
    "Detalle": [
      { "NroLinDet": 1, "NmbItem": "item 1", "QtyItem": 1, "PrcItem": 1500, "MontoItem": 1500 }
    ],
    "Referencia": [
      { "NroLinRef": 1, "TpoDocRef": "33", "FolioRef": "106", "FchRef": "2018-08-16", "CodRef": "3" }
    ]
  }
}
```

---

## 7. Errores de emisión

Cuando el documento enviado (`dte`) presenta errores, la respuesta los describe mediante un código y una descripción. Si es propicio, se indicará en qué campos se produjo el error, con un detalle por cada campo (`details`).

### 7.1 Códigos de error OF-xx

| Código | Descripción |
|---|---|
| `OF-01` | Faltan datos obligatorios. |
| `OF-02` | Faltan campos obligatorios en el `dte`. |
| `OF-03` | Validación de Permisos. |
| `OF-04` | Validación de Firma electrónica. |
| `OF-05` | Tipo DTE no soportado. |
| `OF-06` | Validación Idempotencia. |
| `OF-07` | Validación de Folios. |
| `OF-08` | Validación de Esquema. |
| `OF-09` | Validación de Relaciones. |
| `OF-10` | Validación de Campos. |
| `OF-11` | Validación de PDF. |
| `OF-12` | Generación XML. |
| `OF-13` | Error en DB. |
| `OF-20` | Datos de entrada incorrectos. |
| `OF-21` | Base de datos no disponible, intente más tarde. |
| `OF-22` | Problema al procesar los datos. |
| `OF-23` | DTE no soportado. Se bloquea envío de RVD (ex RCOF) y la emisión de boletas, ya sea porque el usuario se encuentra emitiendo con el SII, el usuario solicitó la baja o se está corrigiendo el folio siguiente del DTE (bloqueo temporal). |

Nota: `OF-10` también se usa para el rechazo por superar el tope mensual de 5 UTM en IVA Artesano (§2.3).

### 7.2 Estructura de la respuesta de error

| Nodo Padre | Campo | Req. | Tipo | Regla |
|---|---|---|---|---|
| error | `message` | * | string | Descripción del error. |
| error | `code` | * | string | Código asignado al error. |
| error | `details` | | arreglo (objetos) | Arreglo con los errores. |

```json
{
  "error": {
    "message": "string",
    "code": "OF-01",
    "details": []
  }
}
```

Estructura de cada elemento de `details`:

| Nodo Padre | Campo | Tipo | Regla |
|---|---|---|---|
| details | `field` | string | Campo del error. |
| details | `issue` | string | Detalle del error. |

```json
{
  "details": [
    { "field": "string", "issue": "string" },
    { "field": "string", "issue": "string" }
  ]
}
```

### 7.3 Ejemplos de respuestas de error

**400 — `OF-10` (Validación de Campos, montos descuadrados):**

```json
{
    "error": {
        "message": "Validación de Campos",
        "code": "OF-10",
        "details": [
            { "field": "MntNeto",  "issue": "Monto erróneo : 1000" },
            { "field": "IVA",      "issue": "Monto erróneo : 190" },
            { "field": "MntTotal", "issue": "Monto erróneo : 119000" }
        ]
    }
}
```

**400 — `OF-06` (Idempotency-Key repetida). Nota: incluye el `token` del documento ya emitido, lo que permite recuperarlo:**

```json
{
    "error": {
        "message": "Este DTE ya fue emitido (Idempotency-Key)",
        "code": "OF-06",
        "token": "c1c13d37566dbdab5a984ab5ebf5e461fba577a3084e44a52151d25a7ded63a8"
    }
}
```

**403 — Autenticación inválida (apikey incorrecta):**

```json
{ "message": "Invalid authentication credentials" }
```

**429 — Límite de peticiones excedido:**

```json
{ "message": "API rate limit exceeded" }
```

---

## 8. Emisión de enlace de autoservicio (`selfService`)

`POST /v2/dte/document` — mismo endpoint y headers que la emisión estándar (incluye soporte de `Idempotency-Key`).

De forma complementaria a las emisiones de DTE, se puede generar un **enlace de autoservicio**. Estos enlaces permiten al cliente **emitir una factura de manera autónoma**, sin tener que solicitar su generación. Es útil cuando la captura de datos para la empresa no se realiza oportunamente (p. ej., el cliente quiere factura pero no entregó sus datos al momento de la venta).

La estructura de la API es la misma de una emisión de DTE; solo se incorporan los campos `customer`, `customizePage` y `selfService`.

### 8.1 Body

| Campo | Requerido | Tipo |
|---|---|---|
| `dte` | * | object |
| `response` | | array |
| `customer` | | object |
| `customizePage` | | object |
| `selfService` | * | object |

### 8.2 `response[]` en autoservicio

Adicional a los parámetros de emisión (`FOLIO`, `PDF`, `XML`, etc.) se incorpora el valor **`SELF_SERVICE`**:

| Nodo Padre | Campo | Tipo |
|---|---|---|
| response | `SELF_SERVICE` | string |

```json
{ "response": ["FOLIO", "SELF_SERVICE"] }
```

### 8.3 `dte` en autoservicio

Mantiene la misma estructura que una emisión de DTE **a excepción** de estos campos de `IdDoc`:

| Nodo Padre | Campo | Req. |
|---|---|---|
| IdDoc | `TipoDTE` | **No es requerido.** |
| IdDoc | `Folio` | **No es requerido.** |

### 8.4 `customer` y `customizePage`

**`customer`** — información usada para el correo enviado y para mostrar en la interfaz del autoservicio:

| Nodo Padre | Campo | Tipo |
|---|---|---|
| customer | `fullName` | string |
| customer | `email` | string |

**`customizePage`** — permite agregar un logo personalizado en la interfaz del autoservicio y mostrar la referencia a la orden de compra:

| Nodo Padre | Campo | Tipo |
|---|---|---|
| customizePage | `externalReference` | object |
| externalReference | `hyperlinkText` | string |
| externalReference | `hyperlinkURL` | string |
| customizePage | `urlLogo` | string |

```json
{
  "customizePage": {
    "externalReference": {
      "hyperlinkText": "Orden de Compra #7788489532",
      "hyperlinkURL": "https://www.miurl.com/orden-de-compra/334"
    },
    "urlLogo": "https://www.miurl.com/logo.jpg"
  }
}
```

### 8.5 `selfService` — reglas de emisión

| Nodo Padre | Campo | Descripción | Tipo |
|---|---|---|---|
| selfService | `issueBoleta` | Indica si debe o no emitir inmediatamente la boleta. | boolean |
| selfService | `allowFactura` | Indica si permite al cliente, cuando ingrese al autoservicio, emitir la factura. | boolean |
| selfService | `documentReference` | | object |
| documentReference | `type` | Tipo de documento a referenciar en la boleta y/o factura (ej.: `"801"` orden de compra). | string |
| documentReference | `id` | Id del documento que referencia. | number |
| documentReference | `date` | Fecha, formato `YYYY-MM-DD`. | string |

```json
{
  "selfService": {
    "issueBoleta": true,
    "allowFactura": true,
    "documentReference": {
      "type": "801",
      "id": "334",
      "date": "2025-01-31"
    }
  }
}
```

**Reglas de fecha de emisión.** La emisión de la boleta o factura se aplica en base a las siguientes reglas. Ejemplo: si la fecha de emisión (`FchEmis`) del enlace de autoservicio es dentro de enero:

- **Caso A — `issueBoleta = true`** (enlace con generación automática de boleta):
  1. Si el cliente convierte a factura **dentro de los primeros 10 días** del período siguiente (febrero), la factura queda con fecha de la orden de compra de enero (`FchEmis`).
  2. Si el cliente convierte a factura **luego de los 10 primeros días** del período siguiente (febrero), la factura queda con **fecha actual** (febrero).
- **Caso B — `issueBoleta = false`** (el enlace no tiene ningún documento emitido aún):
  1. El cliente genera boleta o factura y **siempre** queda con la fecha de la orden de compra de enero (`FchEmis`).

Notas operativas:

- Si se desea evitar el uso del enlace fuera del período de emisión, se puede ingresar por interfaz a `espacio.haulmer.com` → Documentos Electrónicos → Links de autoservicio, y **eliminar los enlaces**.
- La emisión de la factura por parte del cliente **gatilla internamente la anulación de la boleta con una nota de crédito**.

### 8.6 Sobre la respuesta en autoservicio

Independientemente de si se solicita la emisión de la boleta, **siempre se realizará la validación de los campos del objeto `dte`**. Así se garantiza que la emisión sea correcta cuando el cliente la genere de forma autónoma. Si se solicita la emisión de la boleta (`issueBoleta: true`), esta se podrá obtener en la misma respuesta, tal como ocurre en una emisión estándar (TOKEN, FOLIO, PDF, etc. según `response[]`).

Los ejemplos de respuesta publicados para esta variante son los mismos 12 de la emisión estándar (§5 y §7.3); la fuente no incluye un ejemplo del valor retornado en `SELF_SERVICE` (es la URL del enlace).

---

## 9. Historial de cambios relevante e inconsistencias conocidas de la fuente

### Changelog relevante a emisión

| Fecha | Cambio |
|---|---|
| 28/05/2026 | Soporte de Guías de Despacho según **Resolución 154/2025**. Los nuevos campos son opcionales por ahora, retornan `WARNING` si no se envían, y serán obligatorios próximamente. (También se agregó `registry/sync-rcv`, fuera del alcance de este doc.) |
| 10/02/2026 | Se agregó `MedioPago` para boletas y se modificó la regla del campo `RznSocRecep` (obligatorio cuando monto total > 135 UF). |
| 06/08/2025 | Nuevo campo `ivaExceptional` para IVA de artesanos. |
| 03/04/2025 | Se elimina interfaz de ambiente demo. Integración 100% vía API. |
| 01/02/2025 | Emisión de enlaces para autoservicio por API. |
| 31/01/2025 | Se incorpora campo `sendEmail` en API emisión DTE. |

### Inconsistencias / puntos dudosos de la documentación oficial

Estos puntos vienen así en la fuente; se documentan para no inducir a error:

1. **`Receptor.Contacto` marcado como requerido (\*)** en la tabla, pero varios ejemplos oficiales de emisión exitosa lo omiten (Factura 33, Guía 52) o lo envían como el string `"null"` (Liquidación 43). En la práctica no parece bloquear la emisión.
2. **`RznSocRecep` marcado como requerido (\*)** en la tabla, pero la regla adjunta dice "obligatorio cuando el monto total > 135 UF" (regla modificada el 10/02/2026). Para boletas, los ejemplos solo envían `RUTRecep`.
3. **Ejemplo OF-10 incongruente**: el request envía `MntNeto: 100, IVA: 19, MntTotal: 119` pero los `issue` reportan `1000 / 190 / 119000`. Interpretar los `issue` como ilustrativos del formato ("Monto erróneo : <valor>") y no como cálculo literal de ese request.
4. **`ValorDR` tipado como `int`** aunque `TpoValor` admite `"%"`; el formato SII admite decimales en porcentajes. Ante dudas, validar contra el formato oficial del SII.
5. La respuesta de límite de tasa aparece con **dos mensajes distintos**: `"Rate limit is exceeded. Try again in X seconds."` (intro, con `statusCode: 429`) y `"API rate limit exceeded"` (ejemplo del endpoint). Manejar ambos.
6. La cabecera de idempotencia aparece como **`Idempotency-Key`** en la doc (no `X-Idempotency-Key`).
7. Las tablas de campos oficiales cubren solo el subconjunto más común; campos como `TasaIVA`, `MontoPeriodo`, `TotalPeriodo`, `CdgSIISucur`, `IndServicio`, `TipoDespacho`, `IndTraslado`, `GuiaExport`, `Transporte.*`, `Referencia.*` y `TpoDocLiq` solo se conocen por los ejemplos; su definición normativa completa está en el formato de documentos electrónicos del SII.
8. La fuente no detalla los campos nuevos de la **Resolución 154/2025** para guías (52); solo el changelog los menciona como opcionales-con-WARNING.
9. Los tipos de DTE **46, 110, 111 y 112** no tienen ejemplos ni reglas en la doc de emisión; de estar soportados para la cuenta, siguen el formato SII con la misma nomenclatura JSON.
