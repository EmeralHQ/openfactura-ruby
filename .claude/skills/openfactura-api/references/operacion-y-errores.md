# OpenFactura API — Operación, autenticación, límites, historial de cambios y errores

Referencia operacional de la API de OpenFactura (Haulmer): autenticación, ambientes, rate limits, API keys sandbox, historial de cambios de la API, buenas prácticas para producción, preguntas frecuentes y códigos de error consolidados.

OpenFactura utiliza una API RESTful basada en HTTP. Las peticiones y respuestas se hacen mediante mensajes formateados en **JSON**.

> OpenFactura ofrece un entorno de desarrollo completamente operativo para que los desarrolladores puedan integrar sus aplicaciones y sistemas **sin requerir una cuenta**. Las emisiones en este ambiente utilizan un CAF simulado, por lo que el timbre no puede ser validado.

Comunidad: canal de Slack para consultas y comentarios de integración — https://haulmer.slack.com (invitación: https://communityinviter.com/apps/haulmer/haulmer).

---

## 1. Autenticación (header `apikey`)

Todas las peticiones a la API de OpenFactura deben contener en la cabecera la credencial *API Key*, en el header:

```
apikey: <API_KEY>
```

- La API Key es utilizada para verificar los permisos sobre el *endpoint* al que se intenta acceder, además de identificar quién realiza la petición sobre el sistema.
- Las *API Keys* generadas por el sistema están **siempre asociadas a un usuario-empresa**. Todas las consultas realizadas con una API Key estarán ligadas a las acciones del "dueño" de la empresa.
- OpenFactura solo genera **una API Key por Contribuyente**.

**Cómo obtener la API Key de producción** (según el centro de ayuda de Haulmer, help.haulmer.com): la empresa debe estar operativa y haber completado el proceso de certificación ante el SII con el equipo de habilitación. Luego, en la plataforma OpenFactura con la cuenta del titular: Configuración → sección API → botón "GENERAR API KEY".

Cuando exista un error de validación de la API Key, el sistema responde con HTTP **401**:

```json
{ "statusCode": 401, "message": "Access denied due to invalid subscription key. Make sure to provide a valid key for an active subscription." }
```

---

## 2. URLs por ambiente

Existen dos URLs para las APIs, una para cada ambiente:

| Ambiente | Base URL |
|---|---|
| Producción | `https://api.haulmer.com` |
| Desarrollo | `https://dev-api.haulmer.com` |

Los endpoints DTE viven bajo el prefijo `/v2/dte` (p. ej. `https://api.haulmer.com/v2/dte/organization`).

Al pasar a producción hay que cambiar **tanto** la API Key (por la de la empresa real) **como** la base URL a `https://api.haulmer.com`.

---

## 3. Rate limits

Límites globales de la API:

- **Límite de consultas por segundo: 3**
- **Límite de consultas por minuto: 100**

Cuando se alcanza alguno de estos límites, el sistema responde con HTTP **429** y el mensaje:

```json
{ "statusCode": 429, "message": "Rate limit is exceeded. Try again in X seconds." }
```

Además de este límite global, el endpoint `POST /v2/dte/registry/sync-rcv` aplica un **rate limit propio por (contribuyente, tipo de registro)** con contadores separados para `purchase` y `sales`, cuyo valor puede variar dinámicamente según las restricciones del SII. Sus respuestas 429 usan el código `OF-429` e incluyen `retry_after` (segundos restantes del bloqueo) y `ends_at` (fecha-hora exacta de fin de la ventana de bloqueo). Ver `registros-y-organizacion.md`, sección 3.

---

## 4. API keys sandbox públicas

OpenFactura dispone de dos *API Keys* públicas para facilitar y agilizar la integración con la API en el ambiente de desarrollo (`https://dev-api.haulmer.com`). Las observadas en la documentación oficial (colección Postman) son:

| API Key | Uso observado en la documentación |
|---|---|
| `928e15a2d14d4a6292345f04960f4bd3` | Usada en los ejemplos de la mayoría de los endpoints (registros, organization, taxpayer, documentos, emisión) |
| `41eb78998d444dbaa4922c410ef14057` | Usada en el ejemplo del endpoint `registry/sync-rcv` |

Estas keys son solo para sandbox: las emisiones usan CAF simulado y el timbre no es validable. La API Key de producción se genera desde la Plataforma de OpenFactura (ver Preguntas frecuentes, sección 7.1).

---

## 5. Historial de cambios de la API

Tabla completa del changelog oficial (útil para mantener el gem al día):

| Fecha | Detalle Cambio |
|---|---|
| 28/05/2026 | Se incorpora el nuevo endpoint `registry/sync-rcv`, que permite la sincronización de registros de compra y venta desde el SII hacia nuestro servicio. Se actualiza el soporte de Guías de Despacho según Resolución 154/2025. Los nuevos campos actualmente son opcionales, pero retornarán WARNING si no son enviados y serán obligatorios próximamente. |
| 10/02/2026 | Se agregó `MedioPago` para boletas y se modificó regla para campo `RznSocRecep`. |
| 06/08/2025 | Se agrega nuevo campo `ivaExceptional` para hacer uso de IVA para artesanos. |
| 03/04/2025 | Se elimina interfaz de ambiente demo. Integración es 100% vía API. |
| 01/02/2025 | Se puede usar emisión de enlaces para autoservicio por API. |
| 31/01/2025 | Se incorpora campo `sendEmail` de enviar email en API emisión DTE. |
| 27/12/2024 | Dos nuevos campos para filtrar DTE: `FchRecepOF` y `FchRecepSII`. |

Documentación SII de referencia (la API de emisión sigue la misma convención de nombres y jerarquía del SII, en formato compatible con JSON):

- Formato de documentos electrónicos del SII: http://www.sii.cl/factura_electronica/factura_mercado/formato_dte.pdf
- Formato boletas electrónicas del SII: http://www.sii.cl/factura_electronica/factura_mercado/boletas_elec_020.pdf

---

## 6. Buenas prácticas para producción

### 6.1 Idempotency Key

Utilizar siempre que sea posible la **idempotencia** para las emisiones de DTE; de esta forma se tiene la seguridad de que al reintentar **no se producirá una doble emisión** en el sistema.

Dependiendo de la integración, la *Idempotency Key* va a variar. El cliente es responsable de asegurar su **unicidad**; los usos más comunes corresponden a: el número de la orden de compra, un número aleatorio generado en la sesión del cliente, entre muchos otros.

### 6.2 Generación PDF

Con el fin de reducir los tiempos de respuesta durante una emisión, tener en consideración que la **generación del PDF puede llegar a representar hasta el 60% del tiempo de una emisión**.

Dependiendo del tipo de integración, hay casos en que no es necesario contar con el PDF en el mismo instante de la emisión del DTE (p. ej. porque se cuenta con representación propia de 57mm, 80mm o PDF). Para esos casos se recomienda **no solicitar el PDF** en la respuesta (objeto `response` de la API de Emisión), reduciendo drásticamente los tiempos de respuesta.

Si no se solicita el PDF en la emisión, cuando el PDF sea requerido — ya sea vía API o interfaz de OpenFactura — se generará en el momento con la configuración que se haya mandado en el objeto `response` (`80MM` o `LETTER`).

---

## 7. Preguntas frecuentes

### 7.1 ¿Dónde solicito mi *API Key* de producción?

Se puede generar la *API Key* desde la Plataforma de OpenFactura. Tutorial oficial: https://help.haulmer.com/hc/api/como-obtengo-la-api-key-de-openfactura-aa728802-2fe2-4f3d-9bb5-2113c357ba6a

### 7.2 ¿Qué debo hacer para pasar a producción?

Además de contar con la *API Key* de la empresa que se desea integrar, se debe tener especial cuidado en cambiar la URL de conexión con OpenFactura por la de producción: `https://api.haulmer.com`.

### 7.3 ¿Cómo sé si el DTE fue emitido correctamente?

Si luego de la emisión recibes el *token* del documento, quiere decir que fue recepcionado correctamente por el sistema OpenFactura. Para confirmar que el documento ya fue entregado al S.I.I. se puede consultar la API `status` del documento. El tiempo de entrega del documento al S.I.I. varía según la cantidad de emisiones realizadas; en la mayoría de los casos no debe tomar más de **3 minutos**.

### 7.4 ¿Dónde subo o gestiono los CAF?

OpenFactura se encarga de **gestionar los CAF automáticamente** para todos los clientes, por lo tanto ya no se deben subir los CAF de forma manual en el sistema.

### 7.5 ¿Qué puedo hacer si no tengo folios para emitir?

Ya que la gestión de CAF se hace de forma automática, cuando el sistema no es capaz de generar un nuevo CAF se debe principalmente a que el contribuyente tiene **situaciones pendientes con el S.I.I.** En la medida de lo posible, se notificará al Contribuyente con problemas antes de que el CAF sea consumido en su totalidad, para evitar que quede inoperable.

---

## 8. Códigos de error HTTP y formato de errores (consolidado)

### 8.1 Errores de plataforma (gateway)

Formato: `{ "statusCode": <int>, "message": <string> }`.

| HTTP | Causa | Cuerpo de respuesta |
|---|---|---|
| 401 | API Key inválida o suscripción inactiva | `{ "statusCode": 401, "message": "Access denied due to invalid subscription key. Make sure to provide a valid key for an active subscription." }` |
| 429 | Rate limit global excedido (3 req/s o 100 req/min) | `{ "statusCode": 429, "message": "Rate limit is exceeded. Try again in X seconds." }` |

### 8.2 Errores de negocio (códigos `OF-*`)

Los endpoints de la API pueden retornar errores con un código propio con prefijo `OF-` acompañado de `message`. Los documentados para los endpoints de registros son:

| HTTP | Código | Endpoint | Causa | Manejo recomendado |
|---|---|---|---|---|
| 429 | `OF-429` | `POST /v2/dte/registry/sync-rcv` | Rate limit por (contribuyente, tipo de registro) excedido; la solicitud **no se encola**. | Backoff respetando `retry_after` (segundos); persistir `ends_at` (fin de la ventana de bloqueo); no asumir `rate_limit` estático; reintentos separados para `purchase` y `sales`. |
| 400 | `OF-10` | `POST /v2/dte/registry/sync-rcv` | Parámetros inválidos: `periodo` fuera de rango (máximo: período actual + 2 meses, formato `YYYYMM`) o `registro` distinto de `purchase`/`sales`; la solicitud **no se encola**. | Validar `periodo` y `registro` localmente antes de enviar (idealmente en la UI si hay selección manual). |

### 8.3 Resumen de campos de error

| Campo | Dónde aparece | Significado |
|---|---|---|
| `statusCode` | Errores de gateway (401, 429 global) | Código HTTP repetido en el cuerpo |
| `message` | Todos los errores | Descripción legible del error |
| `code` | Errores de negocio (`OF-*`) | Código de error de OpenFactura |
| `retry_after` | 429 `OF-429` de sync-rcv | Segundos restantes para que expire el bloqueo |
| `ends_at` | 429 `OF-429` de sync-rcv | Fecha y hora exacta en que finaliza la ventana de bloqueo |
| `rate_limit` | Contexto de sync-rcv | Límite efectivo vigente; valor dinámico según políticas del SII |
