# OpenFactura API — Consulta e intercambio de documentos (DTE)

Referencia de los endpoints de consulta de documentos emitidos/recibidos, obtención de un documento individual (JSON/XML/PDF/estado), acuse de recibo y anulación de Guía de Despacho (DTE 52).

**Base URLs:**

| Ambiente | URL |
|---|---|
| Producción | `https://api.haulmer.com` |
| Desarrollo | `https://dev-api.haulmer.com` |

**Autenticación:** todas las peticiones llevan el header `apikey: <APIKEY>` (string, requerido). Las peticiones POST llevan además `Content-Type: application/json`.

---

## 1. Listar documentos emitidos

**POST** `/v2/dte/document/issued`

**Headers:** `apikey` (requerido), `Content-Type: application/json`.

Lista los documentos emitidos por el contribuyente. Se envía un JSON con los filtros que se aplicarán a la búsqueda. La API devuelve un **máximo de 30 documentos por petición**, por lo que existe paginación que también se incluye en el JSON. **Si no se envían filtros, la API retorna todos los documentos emitidos.**

### Filtros

Existen tres `variables` de filtro; cada una puede contener tantos `operadores` como se desee para lograr la búsqueda.

| Variable | Req. | Tipo | Reglas | Descripción |
|---|---|---|---|---|
| `RUTRecep` | | int | | Rut emisor¹ |
| `FchEmis` | | string | `YYYY-mm-dd` | Fecha DTE |
| `TipoDTE` | | int | | Tipo DTE |

¹ Así aparece en la documentación oficial, pero por el nombre del campo y la tabla de respuesta corresponde al **Rut del receptor** (en documentos emitidos el contribuyente es el emisor).

### Operadores para las variables

| Operador | Descripción |
|---|---|
| `eq` | Equivale al operador `=` |
| `lt` | Equivale al operador `<` |
| `gt` | Equivale al operador `>` |
| `lte` | Equivale al operador `<=` |
| `gte` | Equivale al operador `>=` |
| `ne` | Equivale al operador `!=` |

### Paginación

Incluir en el JSON la variable `Page`, que indica qué página del resultado se desea obtener (en los ejemplos oficiales se envía como string, ej. `"Page": "1"`).

### Ejemplos de request

```json
{
  "Page": "1",
  "TipoDTE": { "eq": "33" },
  "FchEmis": { "eq": "2019-01-23" },
  "RUTRecep": { "eq": 76264675 }
}
```

Rango de fechas (varios operadores sobre la misma variable):

```json
{
  "Page": "1",
  "TipoDTE": { "eq": "39" },
  "FchEmis": { "gte": "2025-01-01", "lte": "2025-04-11" }
}
```

### Respuesta

| Campo | Tipo | Descripción |
|---|---|---|
| `current_page` | int | Página solicitada |
| `last_page` | int | Última página disponible |
| `data` | array | Datos de la búsqueda |
| `total` | int | Número total de documentos encontrados |

### Campos de cada elemento de `data`

| Nodo Padre | Campo | Tipo | Descripción |
|---|---|---|---|
| data | `RUTRecep` | int | Rut del receptor |
| data | `DV` | string | Dígito Verificador del Rut receptor |
| data | `RznSocRecep` | string | Razón social del receptor |
| data | `TipoDTE` | int | Tipo de documento |
| data | `Folio` | int | Folio del documento |
| data | `FchEmis` | string | Fecha de emisión del documento (`YYYY-mm-dd`) |
| data | `FechaRecibido` | string | Fecha de recepción (`YYYY-mm-dd HH:mm:ss`) |
| data | `MntExe` | int | Monto exento |
| data | `MntNeto` | int | Monto neto |
| data | `IVA` | int | Impuesto del IVA |
| data | `MntTotal` | int | Monto total |
| data | `FmaPago` | string | Forma de pago |
| data | `token` | string | Token del documento (sirve para consultar el documento vía `GET /v2/dte/document/{token}/{value}`) |

---

## 2. Listar documentos recibidos

**POST** `/v2/dte/document/received`

**Headers:** `apikey` (requerido), `Content-Type: application/json`.

Lista los documentos recibidos por el contribuyente. Se envía un JSON con los filtros de búsqueda. La API devuelve un **máximo de 30 documentos por petición** (resultado paginable). **Si no se envían filtros, la API retorna todos los documentos recibidos.**

### Filtros

Existen cinco `variables` de filtro; cada una puede contener tantos `operadores` como se desee.

| Variable | Req. | Tipo | Reglas | Descripción |
|---|---|---|---|---|
| `RUTEmisor` | | int | | Rut emisor |
| `FchEmis` | | string | `YYYY-mm-dd` | Fecha DTE |
| `TipoDTE` | | int | | Tipo DTE |
| `FchRecepOF` | | string | `YYYY-mm-dd` | Fecha de recepción del DTE en Openfactura |
| `FchRecepSII` | | string | `YYYY-mm-dd` | Fecha de recepción del DTE por el SII |

### Operadores para los filtros

Mismos que en documentos emitidos: `eq` (`=`), `lt` (`<`), `gt` (`>`), `lte` (`<=`), `gte` (`>=`), `ne` (`!=`).

### Paginación

Variable `Page` en el JSON, indica qué página se desea obtener.

### Ejemplo de request

```json
{
  "Page": "1",
  "TipoDTE": { "eq": "33" },
  "FchRecepSII": { "eq": "2019-01-23" },
  "RUTEmisor": { "eq": "76264675" }
}
```

### Respuesta

| Campo | Tipo | Descripción |
|---|---|---|
| `current_page` | int | Página solicitada |
| `last_page` | int | Última página disponible |
| `data` | array | Datos de la búsqueda |
| `total` | int | Número total de documentos encontrados |

### Campos de cada elemento de `data`

| Nodo Padre | Campo | Tipo | Descripción |
|---|---|---|---|
| data | `RUTEmisor` | int | Rut del emisor |
| data | `DV` | string | Dígito Verificador del Rut emisor |
| data | `RznSoc` | string | Razón social emisor |
| data | `TipoDTE` | int | Tipo de documento |
| data | `Folio` | int | Folio del documento |
| data | `FchEmis` | string | Fecha de emisión del documento |
| data | `FchRecepSII` | string | Fecha de recepción del documento SII |
| data | `FchRecepOF` | string | Fecha de recepción del documento OF |
| data | `MntExe` | int | Monto exento |
| data | `MntNeto` | int | Monto neto |
| data | `IVA` | int | Monto del IVA |
| data | `MntTotal` | int | Monto total |
| data | `Acuses` | array | Acuses del documento |
| data | `FmaPago` | string | Forma de pago |
| data | `TpoTranCompra` | int | Tipo de compra |

### Fecha de recepción (`FchRecepSII` / `FchRecepOF`)

Estos campos son útiles para detectar DTE nuevos que llegan con una fecha distinta a la de su emisión `FchEmis`. Ejemplo: un documento emitido el 16 de diciembre con fecha de emisión al 3 de diciembre tendrá:

- `FchEmis: 2024-12-03`
- `FchRecepSII: 2024-12-16`
- `FchRecepOF: 2024-12-16`

Las fechas de recepción SII y OF pueden variar por horas entre sí. `FchRecepSII` puede encontrarse **inicialmente en blanco** porque su obtención depende de procesamientos internos que se conectan al SII a recuperar esa información del DTE. `FchRecepOF` **siempre** tendrá un valor de fecha.

### Estructura de `Acuses`

| Nodo Padre | Campo | Tipo | Descripción |
|---|---|---|---|
| Acuses | `codEvento` | string | Tipo de acuse |
| Acuses | `fechaEvento` | string | Fecha del acuse |
| Acuses | `estado` | string | Estado del acuse |

### Tabla `FmaPago`

| Valor | Descripción |
|---|---|
| 1 | Contado |
| 2 | Crédito |
| 3 | Sin costo (entrega gratuita) |

### Tabla `TpoTranCompra`

| Valor | Descripción |
|---|---|
| 1 | Compras del giro |
| 2 | Compras en Supermercados o similares |
| 3 | Adquisición Bien Raíz |
| 4 | Compra Activo Fijo |
| 5 | Compra con IVA Uso Común |
| 6 | Compra sin derecho a crédito |
| 7 | Compra que no corresponde incluir |

---

## 3. Acuse de recibo de documentos recibidos

**POST** `/v2/dte/document/received/accuse`

**Headers:** `apikey` (requerido, string), `Content-Type: application/json`.

API para dar acuse a documentos recibidos. Se envía un JSON identificando el documento al que se quiere dar acuse.

### Tipos de acuse

| Acuse | Descripción |
|---|---|
| `ACD` | Acepta Contenido del Documento |
| `RCD` | Reclamo al Contenido del Documento |
| `ERM` | Otorga Recibo de Mercaderías o Servicios |
| `RFP` | Reclamo por Falta Parcial de Mercaderías |
| `RFT` | Reclamo por Falta Total de Mercaderías |

### Parámetros JSON (body)

| Campo | Requerido | Tipo | Descripción |
|---|---|---|---|
| `rut` | * | string | RUT del emisor (formato con guion y DV, ej. `"76795561-8"`) |
| `dte` | * | int | Tipo dte |
| `folio` | * | int | Folio del documento |
| `acuse` | * | int¹ | Tipo de acuse |

¹ La documentación declara `acuse` como int, pero el valor real es uno de los códigos string de la tabla de acuses (`ACD`, `RCD`, `ERM`, `RFP`, `RFT`), como muestra el ejemplo oficial.

### Ejemplo de request

```json
{ "dte": 33, "folio": 2514, "rut": "76795561-8", "acuse": "ACD" }
```

### Respuesta

| Campo | Tipo |
|---|---|
| `data` | array |
| `code` | int |
| `result` | string |
| `msg` | array |

Estructura de `data`:

| Campo | Tipo |
|---|---|
| `dte` | int |
| `folio` | int |
| `acuse` | string |

Estructura de `msg`:

| Campo | Tipo |
|---|---|
| `codResp` | int |
| `descResp` | string |

---

## 4. Obtener un documento por RUT, tipo y folio

**GET** `/v2/dte/document/{rut}/{type}/{document-number}/{value}`

**Headers:** `apikey` (requerido, string).

Entrega la información de un documento **emitido o recibido** en Openfactura.

Ejemplo de URL: `https://dev-api.haulmer.com/v2/dte/document/76430498-5/33/26005/json`

### Parámetros URL

| Campo | Requerido | Tipo | Descripción |
|---|---|---|---|
| `rut` | * | string | Rut del Contribuyente emisor (con guion y DV) |
| `type` | * | int | Tipo de Documento |
| `document-number` | * | int | Folio del documento |
| `value` | * | string | Valor a buscar: `status`, `xml`, `json`, `pdf`, `cedible` |

### Valores posibles de `value`

| `value` | Qué retorna |
|---|---|
| `status` | Estado del documento (ver tablas de estados abajo) |
| `xml` | XML del DTE, **codificado en base64** |
| `json` | Representación JSON del DTE (Encabezado, Detalle, Referencia, Totales, etc.) |
| `pdf` | PDF del DTE, **codificado en base64** |
| `cedible` | Genera una copia cedible en formato PDF del documento (base64) |

Notas:

- Si es `xml` o `pdf`, el contenido se retorna **codificado en base64**.
- Si NO se solicitó el PDF durante la emisión, este será generado en el momento de esta petición, considerando el formato solicitado al momento de la emisión (`LETTER` u `80MM`).

### Estados (`value = status`)

La respuesta de `status` depende de si el documento es emitido o recibido.

Documentos **emitidos** — cuatro posibles respuestas:

| Estado | Significado |
|---|---|
| `Aceptado` | Documento Emitido correctamente en el SII |
| `Pendiente` | Esperando Respuesta del SII |
| `Rechazado` | Documento Rechazado por el SII |
| `Aceptado con Reparo` | Documento válido para el SII, pero con reparos |

Documentos **recibidos** — cuatro posibles respuestas:

| Estado | Significado |
|---|---|
| `Pendiente` | Todavía no se da acuse de Documento recibido |
| `Registrado` | Documento aceptado por el receptor |
| `No_incluir` | No se incluye en el registro de Compra |
| `Reclamado` | Documento rechazado por el receptor |

> El estado `Registrado` se activa **automáticamente** si han pasado **8 días** de estar en `Pendiente`.

### Respuesta

La respuesta depende del `value` ingresado en la URL. Campos posibles:

| Campo | Tipo |
|---|---|
| `pdf` | string |
| `json` | string |
| `xml` | string |
| `status` | string |
| `folio` | string |
| `cedible` | string |

### Ejemplo de response (`value = json`, 200 OK)

```json
{
  "json": {
    "Encabezado": {
      "IdDoc": { "TipoDTE": 33, "Folio": 26005, "FchEmis": "2025-03-23" },
      "Emisor": {
        "RUTEmisor": "76430498-5",
        "RznSoc": "HOSTY SPA",
        "GiroEmis": "ACTIVIDADES DE CONSULTORIA DE INFORMATICA...",
        "CorreoEmisor": "fdgsfg@sdfgs.com",
        "Acteco": [620200],
        "DirOrigen": "ARTURO PRAT 527 3 pis OF 1",
        "CmnaOrigen": "Curicó"
      },
      "Receptor": {
        "RUTRecep": "76795561-8",
        "RznSocRecep": "HAULMER CHILE SPA",
        "GiroRecep": "PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET...",
        "Contacto": "haulmer1@haulmer.com",
        "DirRecep": "A PRAT 545 DP 2",
        "CmnaRecep": "Curicó"
      },
      "Totales": { "MntNeto": 10600, "MntExe": 0, "IVA": 0, "MntTotal": 12614 }
    }
  },
  "folio": 26005,
  "FchRecepSII": "2025-03-23 11:56:43",
  "FchRecepOF": "2025-04-05 11:01:47"
}
```

---

## 5. Obtener un documento por token

**GET** `/v2/dte/document/{token}/{value}`

**Headers:** `apikey` (requerido, string).

Entrega la información de un documento **emitido** en Openfactura basado en el `token` del documento, que es obtenido durante la emisión (también aparece en el campo `token` de cada elemento de `/document/issued`).

Ejemplo de URL: `https://dev-api.haulmer.com/v2/dte/document/af7f8fc6c3856e38d231d3ee8461cf3e7f2f539541edc3692f0078f5abfa6ff4/json`

### Parámetros URL

| Campo | Requerido | Tipo | Descripción |
|---|---|---|---|
| `token` | * | string | Token a buscar |
| `value` | * | string | Valor a buscar: `status`, `xml`, `json`, `pdf`, `cedible` |

### Valores posibles de `value`

Mismos que el endpoint anterior: `status`, `xml`, `json`, `pdf`, `cedible`.

- Si es `xml` o `pdf`, el contenido está **codificado en base64**.
- `cedible` genera una copia cedible en formato PDF del documento.
- Si NO se solicitó el PDF durante la emisión, se genera en el momento de esta petición, en el formato solicitado en la emisión (`LETTER` u `80MM`).

Para `status` existen cuatro posibles respuestas (solo estados de documento emitido):

| Estado | Significado |
|---|---|
| `Aceptado` | Documento Emitido correctamente en el SII |
| `Pendiente` | Esperando Respuesta del SII |
| `Rechazado` | Documento Rechazado por el SII |
| `Aceptado con Reparo` | Documento válido para el SII, pero con reparos |

### Respuesta

Depende del `value` ingresado en la URL. Campos posibles:

| Campo | Tipo |
|---|---|
| `pdf` | string |
| `json` | string |
| `xml` | string |
| `status` | string |
| `token` | string |
| `cedible` | string |

### Ejemplos de response (200 OK)

`value = pdf`:

```json
{ "pdf": "JVBERi0xLjcKMSAwIG9iago8...(base64 truncado)...", "folio": 600625 }
```

`value = json` (boleta 39 con detalle y referencia; nótese que aquí los valores numéricos vienen como string):

```json
{
  "json": {
    "Detalle": [
      {
        "CdgItem": { "TpoCodigo": "INT1", "VlrCodigo": "101122146100" },
        "NmbItem": "Cama para Perros William",
        "PrcItem": "39990", "QtyItem": "1", "MontoItem": "39990", "NroLinDet": "1"
      },
      {
        "IndExe": "1", "NmbItem": "Costo Despacho",
        "PrcItem": "2990", "QtyItem": "1", "MontoItem": "2990", "NroLinDet": "2"
      }
    ],
    "Encabezado": {
      "IdDoc": { "Folio": "600625", "FchEmis": "2025-04-11", "TipoDTE": "39", "IndServicio": "3" },
      "Emisor": {
        "DirOrigen": "ARTURO PRAT 527   CURICO", "RUTEmisor": "76795561-8",
        "CmnaOrigen": "Curicó", "GiroEmisor": "VENTA AL POR MENOR...",
        "CdgSIISucur": "81303347", "RznSocEmisor": "HAULMER CHILE SPA"
      },
      "Totales": {
        "IVA": "6385", "MntExe": "2990", "MntNeto": "33605",
        "MontoNF": "0", "MntTotal": "42980", "VlrPagar": "42980"
      },
      "Receptor": { "RUTRecep": "66666666-6" }
    },
    "Referencia": [
      { "RazonRef": "Nota de pedido Nº67966 -  Fecha 2025-04-11", "NroLinRef": "1" }
    ]
  },
  "token": "af7f8fc6c3856e38d231d3ee8461cf3e7f2f539541edc3692f0078f5abfa6ff4",
  "FchRecepSII": "",
  "FchRecepOF": "2025-04-11 23:00:27.0427"
}
```

`value = xml`:

```json
{ "xml": "PD94bWwgdmVyc2lvbj0iMS4wIiBl...(base64 truncado)...", "token": "af7f8fc6c38..." }
```

`value = status` (el campo de respuesta se llama `estado`, no `status`):

```json
{ "estado": "Aceptado", "token": "af7f8fc6c3856e38d231d3ee8461cf3e7f2f539541edc3692f0078f5abfa6ff4" }
```

---

## 6. Anular Guía de Despacho Electrónica (DTE 52)

**POST** `/v2/dte/anularDTE52`

**Headers:** `apikey` (requerido, string), `Content-Type: application/json`.

Permite anular una Guía de Despacho Electrónica (dte 52). Realiza la validación de que **no se pueda anular el documento más de una vez**.

### Parámetros JSON (body)

| Campo | Requerido | Tipo | Descripción |
|---|---|---|---|
| `dte` | * | int | Tipo dte |
| `folio` | * | int | Folio del documento |
| `Fecha` | * | string | Fecha emisión del documento, formato `Y-m-d` |

> Inconsistencia en la documentación oficial: la tabla declara `dte` y `folio` en minúscula, pero el ejemplo oficial envía las claves capitalizadas `Dte` y `Folio` (y `Fecha`).

### Ejemplo de request

```json
{ "Dte": 52, "Folio": 34972, "Fecha": "2020-10-16" }
```

### Respuesta (200 OK)

| Campo | Requerido | Tipo |
|---|---|---|
| `succes`¹ | * | string |

¹ Así aparece en la tabla oficial; el ejemplo real de respuesta usa la clave `success`.

```json
{ "success": "Se ha anulado el documento Folio: 34972" }
```

### Respuesta de error

| Nodo Padre | Campo | Req. | Tipo | Regla |
|---|---|---|---|---|
| error | `message` | * | string | Descripción del error |
| error | `code` | * | string | Código asignado al error (ej. `OF-10`) |
| error | `details` | | arreglo(objetos) | Arreglo con los errores |

| Nodo Padre | Campo | Tipo | Regla |
|---|---|---|---|
| details | `field` | string | Campo del error |
| details | `issue` | string | Detalle del error |

```json
{
  "error": {
    "message": "string",
    "code": "OF-10",
    "details": [
      { "field": "string", "issue": "string" }
    ]
  }
}
```

---

## Tabla resumen de endpoints

| Endpoint | Método | Propósito | Body / Parámetros clave | Retorna |
|---|---|---|---|---|
| `/v2/dte/document/issued` | POST | Listar documentos emitidos (máx. 30 por página) | Filtros `RUTRecep`, `FchEmis`, `TipoDTE` con operadores `eq/lt/gt/lte/gte/ne`; paginación `Page` | `current_page`, `last_page`, `total`, `data[]` (incluye `token` por documento) |
| `/v2/dte/document/received` | POST | Listar documentos recibidos (máx. 30 por página) | Filtros `RUTEmisor`, `FchEmis`, `TipoDTE`, `FchRecepOF`, `FchRecepSII` con los mismos operadores; paginación `Page` | `current_page`, `last_page`, `total`, `data[]` (incluye `Acuses`, `FmaPago`, `TpoTranCompra`) |
| `/v2/dte/document/received/accuse` | POST | Dar acuse a un documento recibido | `rut`, `dte`, `folio`, `acuse` (`ACD`/`RCD`/`ERM`/`RFP`/`RFT`) — todos requeridos | `data` (`dte`, `folio`, `acuse`), `code`, `result`, `msg` (`codResp`, `descResp`) |
| `/v2/dte/document/{rut}/{type}/{document-number}/{value}` | GET | Obtener un documento emitido o recibido por RUT emisor + tipo + folio | Path: `rut`, `type`, `document-number`, `value` ∈ {`status`, `xml`, `json`, `pdf`, `cedible`} | Según `value`: JSON del DTE, XML/PDF/cedible en base64, o estado |
| `/v2/dte/document/{token}/{value}` | GET | Obtener un documento emitido por su token de emisión | Path: `token`, `value` ∈ {`status`, `xml`, `json`, `pdf`, `cedible`} | Según `value`; `status` responde `{ "estado": ..., "token": ... }` |
| `/v2/dte/anularDTE52` | POST | Anular Guía de Despacho Electrónica (DTE 52), una sola vez por documento | `Dte` (52), `Folio`, `Fecha` (`Y-m-d`) — todos requeridos | `success` con mensaje de anulación; error `{ "error": { "message", "code", "details" } }` |
