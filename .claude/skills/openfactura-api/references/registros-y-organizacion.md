# OpenFactura API — Registros de venta/compra, sincronización RCV, organización y contribuyentes

Referencia de los endpoints de consulta de registros (ventas y compras), sincronización RCV desde el SII, datos de la organización, documentos autorizados/folios y consulta de contribuyentes.

Convenciones generales:

- **Base URL producción:** `https://api.haulmer.com`
- **Base URL desarrollo:** `https://dev-api.haulmer.com`
- Todos los endpoints de este documento viven bajo el prefijo `/v2/dte`.
- Todas las peticiones requieren el header `apikey` (string, obligatorio).
- Respuestas y peticiones en JSON.
- Errores transversales: `401` (API Key inválida) y `429` (rate limit global: 3 req/s, 100 req/min). Ver `operacion-y-errores.md` para el detalle y formato.

---

## 1. Registros de venta

### 1.1 Registro diario de ventas — `GET /v2/dte/registry/sales/{year}/{month}/{day}`

Corresponde a la información de un registro diario de ventas. Retorna la cantidad de documentos emitidos en un día y un resumen de los totales por cada tipo de documento.

**Ejemplo de URL:** `https://dev-api.haulmer.com/v2/dte/registry/sales/2020/10/14`

**Headers**

| Campo | Requerido | Tipo |
|---|---|---|
| apikey | * | string |

**Parámetros URL**

| Campo | Requerido | Tipo | Desc. |
|---|---|---|---|
| year | * | int | Año a buscar |
| month | * | int | Mes a buscar |
| day | * | int | Día a buscar |

**Respuesta**

| Campo | Tipo |
|---|---|
| fechaInicio | string |
| fechaFinal | string |
| registros | array |

**Registros** (elementos del array `registros`)

| Nodo Padre | Campo | Tipo |
|---|---|---|
| registros | tipoDocumento | int |
| registros | cantDocumentos | int |
| registros | totalMntExe | int |
| registros | totalMntNeto | int |
| registros | totalMntIVA | int |
| registros | totalMntTotal | int |

> Nota: el ejemplo real de respuesta incluye además el campo `totalOtrosImp` (int) en cada registro, aunque la tabla oficial no lo documenta.

**Ejemplo de respuesta — 200 OK** (recortado; la respuesta real incluye un objeto por cada `tipoDocumento` emitido en el día, p. ej. 33, 34, 39, 41, 52, 61, 801, 802):

```json
{
  "fechaInicio": "2020-10-14",
  "fechaFinal": "2020-10-14",
  "registros": [
    { "tipoDocumento": 33, "cantDocumentos": 32, "totalMntExe": 96, "totalMntNeto": 8032103, "totalMntIVA": 1526097, "totalOtrosImp": 4, "totalMntTotal": 9558300 },
    { "tipoDocumento": 39, "cantDocumentos": 25, "totalMntExe": 86209, "totalMntNeto": 3138097, "totalMntIVA": 596237, "totalOtrosImp": 0, "totalMntTotal": 3820543 },
    { "tipoDocumento": 61, "cantDocumentos": 8, "totalMntExe": 45990, "totalMntNeto": 3134284, "totalMntIVA": 595514, "totalOtrosImp": 0, "totalMntTotal": 3775788 }
  ]
}
```

### 1.2 Registro mensual de ventas — `GET /v2/dte/registry/sales/{year}/{month}`

Corresponde a la información de un registro mensual de emisión de documentos. Retorna la cantidad de documentos emitidos en un mes y un resumen de los totales por cada tipo de documento.

**Ejemplo de URL:** `https://dev-api.haulmer.com/v2/dte/registry/sales/2020/10`

**Headers**

| Campo | Requerido | Tipo |
|---|---|---|
| apikey | * | string |

**Parámetros URL**

| Campo | Requerido | Tipo | Desc. |
|---|---|---|---|
| year | * | int | Año a buscar |
| month | * | int | Mes a buscar |

**Respuesta:** misma estructura que el registro diario (`fechaInicio`, `fechaFinal`, `registros[]` con `tipoDocumento`, `cantDocumentos`, `totalMntExe`, `totalMntNeto`, `totalMntIVA`, `totalMntTotal`, y `totalOtrosImp` en la práctica). `fechaInicio`/`fechaFinal` cubren el mes completo.

**Ejemplo de respuesta — 200 OK** (recortado):

```json
{
  "fechaInicio": "2020-10-01",
  "fechaFinal": "2020-10-31",
  "registros": [
    { "tipoDocumento": 33, "cantDocumentos": 369, "totalMntExe": 123216, "totalMntNeto": 28245342, "totalMntIVA": 5366599, "totalOtrosImp": 466444, "totalMntTotal": 34201601 },
    { "tipoDocumento": 39, "cantDocumentos": 522, "totalMntExe": 504656, "totalMntNeto": 10318450786, "totalMntIVA": 1960505657, "totalOtrosImp": 0, "totalMntTotal": 12279461099 },
    { "tipoDocumento": 56, "cantDocumentos": 4, "totalMntExe": 4000, "totalMntNeto": 87, "totalMntIVA": 17, "totalOtrosImp": 0, "totalMntTotal": 4104 }
  ]
}
```

---

## 2. Registros de compra

### Estados de los documentos recibidos

Existen 4 estados posibles que pueden tener los documentos recibidos. El valor del query param `status` va en inglés; el campo `estado` de la respuesta viene en español:

| Valor `status` (query) | Estado en respuesta | Significado |
|---|---|---|
| `pending` | `Pendiente` | Documento recibido aún sin acción del receptor |
| `registered` | `Registrado` | Documento aceptado/registrado |
| `exclude` | `No_incluir` | Documento marcado como "No incluir" |
| `reclaimed` | `Reclamado` | Documento reclamado |

Para recibir un estado en particular, solo se debe enviar por URL el o los estados que se desea recibir mediante el parámetro `status` (separados por coma, p. ej. `status=pending,exclude`). Si no se envía el parámetro `status`, se devolverán todos los estados en la respuesta.

### 2.1 Registro diario de compras — `GET /v2/dte/registry/purchase/{year}/{month}/{day}`

Entrega la información de un registro diario de Compras. Retorna la cantidad de documentos recibidos en un día y un resumen de los totales por cada tipo de documento.

**Ejemplo de URL:** `https://dev-api.haulmer.com/v2/dte/registry/purchase/2020/10/01?status=pending,exclude`

**Headers**

| Campo | Requerido | Tipo |
|---|---|---|
| apikey | * | string |

**Query Params**

| Campo | Opcional | Tipo | Desc. |
|---|---|---|---|
| status | * | string | Estados a buscar. Ej. "`pending`, `registered`" |

**Parámetros URL**

| Campo | Requerido | Tipo | Desc. |
|---|---|---|---|
| year | * | int | Año a buscar |
| month | * | int | Mes a buscar |
| day | * | int | Día a buscar |

**Respuesta:** a diferencia de ventas, la respuesta es un **arreglo** que contiene un objeto por cada estado.

| Campo | Tipo |
|---|---|
| estado | string |
| fechaInicio | string |
| fechaFinal | string |
| registros | array |

**Registros** (elementos del array `registros`)

| Nodo Padre | Campo | Tipo |
|---|---|---|
| registros | tipoDocumento | int |
| registros | cantDocumentos | int |
| registros | totalMntExe | int |
| registros | totalMntNeto | int |
| registros | totalMntIVA | int |
| registros | totalMntTotal | int |

> Nota: al igual que en ventas, el ejemplo real incluye también `totalOtrosImp` (int). Un estado sin documentos retorna `"registros": []`.

**Ejemplo de respuesta — 200 OK** (con `status=pending,exclude`):

```json
[
  {
    "estado": "Pendiente",
    "fechaInicio": "2020-10-01",
    "fechaFinal": "2020-10-01",
    "registros": []
  },
  {
    "estado": "No_incluir",
    "fechaInicio": "2020-10-01",
    "fechaFinal": "2020-10-01",
    "registros": [
      { "tipoDocumento": 33, "cantDocumentos": 1, "totalMntExe": 0, "totalMntNeto": 12398, "totalMntIVA": 2356, "totalOtrosImp": 0, "totalMntTotal": 14754 }
    ]
  }
]
```

### 2.2 Registro mensual de compras — `GET /v2/dte/registry/purchase/{year}/{month}`

Corresponde a la petición para obtener la información de un registro mensual de compras. Retorna la cantidad de documentos recibidos en un mes y un resumen de los totales por cada tipo de documento.

**Ejemplo de URL:** `https://dev-api.haulmer.com/v2/dte/registry/purchase/2020/10?status=pending,exclude`

**Headers, Query Params y estructura de respuesta:** idénticos al registro diario de compras (2.1), salvo que los Parámetros URL son solo `year` y `month`, y `fechaInicio`/`fechaFinal` cubren el mes completo.

**Ejemplo de respuesta — 200 OK:**

```json
[
  {
    "estado": "Pendiente",
    "fechaInicio": "2020-10-01",
    "fechaFinal": "2020-10-31",
    "registros": []
  },
  {
    "estado": "No_incluir",
    "fechaInicio": "2020-10-01",
    "fechaFinal": "2020-10-31",
    "registros": [
      { "tipoDocumento": 33, "cantDocumentos": 9, "totalMntExe": 0, "totalMntNeto": 4267023, "totalMntIVA": 810208, "totalOtrosImp": 525, "totalMntTotal": 5077756 }
    ]
  }
]
```

---

## 3. Sincronización RCV desde el SII — `POST /v2/dte/registry/sync-rcv` (nuevo, 28/05/2026)

Permite la sincronización de registros de compra y venta (RCV) desde el SII hacia el servicio de OpenFactura. La solicitud se **encola** para procesamiento asíncrono; no retorna los registros directamente (para leerlos, usar los endpoints de `registry/sales` y `registry/purchase`).

**URL:** `https://dev-api.haulmer.com/v2/dte/registry/sync-rcv`

**Headers**

| Campo | Requerido | Tipo |
|---|---|---|
| apikey | * | string |
| Content-Type | * | `application/json` |

**Parámetros JSON (body)**

| Campo | Requerido | Tipo | Desc. |
|---|---|---|---|
| registro | * | string | Corresponde a `purchase` (compra) y `sales` (venta) |
| periodo | * | int | Formato permitido `YYYYMM` |

**Ejemplo de request:**

```json
{ "registro": "sales", "periodo": 202605 }
```

**Respuesta**

| Campo | Tipo |
|---|---|
| message | string |
| code | string |

> Nota: la colección Postman de origen no incluye los cuerpos de respuesta de ejemplo (vienen vacíos), pero sí documenta los campos anteriores y los campos de error `retry_after`, `ends_at` y `rate_limit` descritos abajo.

### Restricciones operacionales

El incumplimiento de estas validaciones provocará respuestas `HTTP 429 (OF-429)` o `HTTP 400 (OF-10)`, y la solicitud de sincronización **no será encolada** para procesamiento.

#### Restricción 1: Rate limit por contribuyente y tipo de registro

- Cada combinación **(contribuyente, tipo de registro)** posee una ventana de consumo independiente.
- El límite **no es global**: las operaciones asociadas a `purchase` y `sales` se contabilizan por separado y mantienen contadores distintos.
- El valor efectivo del `rate_limit` puede **variar dinámicamente** según las restricciones y condiciones impuestas por el SII.

Recomendaciones de implementación:

1. **Implementar estrategias de backoff respetando el valor de `retry_after`.** El campo `retry_after` indica la cantidad de segundos restantes para que el bloqueo expire y se permita nuevamente la ejecución de solicitudes.
2. **Persistir localmente el valor de `ends_at`.** El campo `ends_at` representa la fecha y hora exacta en que finaliza la ventana de bloqueo asociada al rate limit. Almacenarlo evita enviar solicitudes que ya se sabe serán rechazadas.
3. **No asumir valores estáticos de `rate_limit`.** Las restricciones pueden cambiar según las políticas del SII; tratar `rate_limit` como valor variable y adaptable.
4. **Gestionar de forma independiente los flujos `purchase` y `sales`.** Cada tipo de registro mantiene su propia ventana de rate limiting y debe tratarse con lógica de reintentos separada.

#### Restricción 2: Validación del campo `periodo`

El campo `periodo` es validado contra un límite máximo equivalente al **período actual más dos meses**. Por ejemplo, si el período actual es `202605`, el valor máximo permitido será `202607`.

Recomendaciones de implementación:

1. Generar y validar el período localmente usando el formato `YYYYmm`.
2. **Evitar el envío de períodos futuros superiores al límite permitido (+2 meses).** Si la integración permite selección manual de períodos, aplicar esta validación en la interfaz de usuario antes de enviar la solicitud.

### Errores específicos de sync-rcv

| HTTP | Código | Causa |
|---|---|---|
| 429 | `OF-429` | Rate limit por (contribuyente, tipo de registro) excedido. Respetar `retry_after` (segundos) / `ends_at` (fecha-hora fin del bloqueo). |
| 400 | `OF-10` | `periodo` inválido (fuera del rango permitido, formato incorrecto) o `registro` inválido (debe ser exactamente `purchase` o `sales`; p. ej. `"compra"` es rechazado). |

---

## 4. Datos de la organización — `GET /v2/dte/organization`

Entrega la información del Contribuyente asociado a la *API Key* enviada en la petición. OpenFactura solo genera **una API Key por Contribuyente**.

**URL:** `https://dev-api.haulmer.com/v2/dte/organization`

**Headers**

| Campo | Requerido | Tipo |
|---|---|---|
| apikey | * | string |

**Query Params**

| Campo | Opcional | Tipo | Desc. |
|---|---|---|---|
| extra_fields | * | string | Campos adicionales del contribuyente para generar la respuesta. |

**`extra_fields`:** corresponde a campos adicionales que se pueden obtener del contribuyente. Por ahora solo está disponible el campo `logo` (`?extra_fields=logo`), que agrega el logo de la empresa a la respuesta.

**Respuesta**

| Campo | Tipo |
|---|---|
| rut | string |
| razonSocial | string |
| email | string |
| telefono | string |
| direccion | string |
| cdgSIISucur | string |
| glosaDescriptiva | string |
| direccionRegional | string |
| resolucion | object |
| nombreFantasia | string |
| web | string |
| sucursales | array |
| actividades | array |

> Notas: el ejemplo real incluye además `comuna` (string) y `ciudad` (string), no documentados en la tabla oficial. El objeto `resolucion` contiene `fecha` (string, `YYYY-MM-DD`) y `numero` (string). Los elementos de `actividades` tienen la misma forma que en `/taxpayer/{rut}` (ver sección 6).

**Ejemplo de respuesta — 200 OK** (actividades recortadas):

```json
{
  "rut": "76795561-8",
  "razonSocial": "HAULMER CHILE SPA",
  "email": "haulmer1@haulmer.com",
  "telefono": null,
  "direccion": "A PRAT 545 DP 2",
  "cdgSIISucur": "81303347",
  "glosaDescriptiva": "PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET, SOFTWARE, DISPOSITIVO",
  "direccionRegional": "CURICÓ",
  "comuna": "Curicó",
  "ciudad": "",
  "resolucion": { "fecha": "2022-09-07", "numero": "0" },
  "nombreFantasia": "Halumer Pruebas",
  "web": "www.openfactura.cl",
  "sucursales": [],
  "actividades": [
    {
      "giro": "PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET, SOFTWARE, DISPOSITIVO",
      "actividadEconomica": "OTROS TIPOS DE INTERMEDIACION MONETARIA N.C.P.",
      "codigoActividadEconomica": "641990",
      "actividadPrincipal": true
    },
    {
      "giro": "PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET, SOFTWARE, DISPOSITIVO",
      "actividadEconomica": "PROCESAMIENTO DE DATOS, HOSPEDAJE Y ACTIVIDADES CONEXAS",
      "codigoActividadEconomica": "631100",
      "actividadPrincipal": false
    }
  ]
}
```

---

## 5. Documentos autorizados y folios — `GET /v2/dte/organization/document`

Proporciona la información de los tipos de documentos que tiene autorizados el contribuyente junto con la cantidad de folios disponibles y su fecha de vencimiento.

**URL:** `https://dev-api.haulmer.com/v2/dte/organization/document`

**Headers**

| Campo | Requerido | Tipo |
|---|---|---|
| apikey | * | string |

**Respuesta**

| Campo | Tipo |
|---|---|
| rut | string |
| documentos | array |

**Documentos** (elementos del array `documentos`)

| Nodo Padre | Campo | Tipo |
|---|---|---|
| documentos | dte | string |
| documentos | disponible | int |
| documentos | vencimiento | string |

> Nota (discrepancia doc oficial vs. ejemplo real): la tabla oficial declara `dte` como string y el campo de folios como `disponible` (singular), pero en el ejemplo real `dte` es int y el campo se llama `disponibles` (plural). Confiar en el ejemplo: `dte` (int), `disponibles` (int), `vencimiento` (string `YYYY-MM-DD`).

**Códigos DTE.** Cada documento se encuentra normado por el S.I.I. con un código único:

| DTE | Tipo |
|---|---|
| 33 | Factura electrónica |
| 34 | Factura no afecta o exenta electrónica |
| 38 | Boleta exenta |
| 39 | Boleta electrónica |
| 41 | Boleta exenta electrónica |
| 43 | Liquidación factura electrónica |
| 46 | Factura de compra electrónica |
| 52 | Guía de despacho electrónica |
| 56 | Nota de débito electrónica |
| 61 | Nota de crédito electrónica |

**Ejemplo de respuesta — 200 OK** (recortado):

```json
{
  "rut": "76795561-8",
  "documentos": [
    { "dte": 39, "disponibles": 399298, "vencimiento": "2025-10-01" },
    { "dte": 33, "disponibles": 324968, "vencimiento": "2025-10-01" },
    { "dte": 61, "disponibles": 399996, "vencimiento": "2025-10-01" },
    { "dte": 52, "disponibles": 399997, "vencimiento": "2025-10-01" }
  ]
}
```

---

## 6. Consulta de contribuyente — `GET /v2/dte/taxpayer/{rut}`

Entrega la información básica de los Contribuyentes registrados en el S.I.I., la cual puede ser utilizada para complementar la información de `Receptor` durante una emisión.

**Ejemplo de URL:** `https://dev-api.haulmer.com/v2/dte/taxpayer/76795561-8`

**Headers**

| Campo | Requerido | Tipo |
|---|---|---|
| apikey | * | string |

**Parámetros URL**

| Campo | Requerido | Tipo | Desc. |
|---|---|---|---|
| RUT | * | string | Rut del Contribuyente a Buscar (formato con guion y dígito verificador, p. ej. `76795561-8`) |

**Respuesta**

| Campo | Tipo |
|---|---|
| rut | string |
| razonSocial | string |
| email | string |
| telefono | string |
| direccion | string |
| comuna | string |
| actividades | array |
| sucursales | array |

**Actividades**

| Nodo Padre | Campo | Tipo |
|---|---|---|
| actividades | giro | string |
| actividades | actividadEconomica | string |
| actividades | codigoActividadEconomica | int |
| actividades | actividadPrincipal | boolean |

> Nota: la tabla oficial declara `codigoActividadEconomica` como int, pero el ejemplo real lo entrega como string (`"641990"`).

**Sucursales**

| Nodo Padre | Campo | Tipo |
|---|---|---|
| sucursales | cdgSIISucur | string |
| sucursales | comuna | string |
| sucursales | direccion | string |
| sucursales | ciudad | string |
| sucursales | telefono | int |

> Nota: en el ejemplo real `telefono` de la sucursal viene `null`, y el `telefono` de nivel raíz viene como string (`"0"`).

**Ejemplo de respuesta — 200 OK** (actividades recortadas):

```json
{
  "rut": "76795561-8",
  "razonSocial": "HAULMER CHILE SPA",
  "email": "haulmer1@haulmer.com",
  "telefono": "0",
  "direccion": "A PRAT 545 DP 2",
  "comuna": "Curicó",
  "actividades": [
    {
      "giro": "PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET, SOFTWARE, DISPOSITIVO",
      "actividadEconomica": "OTROS TIPOS DE INTERMEDIACION MONETARIA N.C.P.",
      "codigoActividadEconomica": "641990",
      "actividadPrincipal": true
    }
  ],
  "sucursales": [
    {
      "cdgSIISucur": "81303347",
      "comuna": "Curicó",
      "direccion": "A PRAT 545 DP 2",
      "ciudad": "",
      "telefono": null
    }
  ]
}
```
