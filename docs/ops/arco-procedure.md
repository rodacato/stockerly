# Procedimiento operativo ARCO

> Cómo procesar solicitudes de Acceso, Rectificación, Cancelación, Oposición (ARCO) y revocación de consentimiento, conforme a los Arts. 28-32 NLFPDPPP (DOF 20-mar-2025).

---

## 1. Recepción de la solicitud

Las solicitudes llegan por correo a `support@notdefined.dev`. Marca la solicitud en el sistema de tickets con la etiqueta `arco` y registra:

- Fecha y hora de recepción (UTC y hora local CDMX).
- Datos del solicitante (nombre, correo registrado).
- Derecho que ejerce (acceso, rectificación, cancelación, oposición o revocación).
- Descripción exacta de los datos sobre los que recae.

La fecha de recepción inicia el **plazo de 20 días hábiles** (Art. 32 NLFPDPPP).

## 2. Validación de identidad

Antes de cualquier acción, valida que la persona que solicita es titular de los datos:

1. Verifica que el correo desde el que llega la solicitud coincide con el correo registrado en la cuenta.
2. Si hay duda razonable (correo distinto, lenguaje atípico, datos imprecisos), responde solicitando una prueba adicional en los primeros **5 días hábiles**:
   - Captura de pantalla del último correo transaccional recibido de Stockerly, o
   - Confirmación enviada desde el correo registrado a `support@notdefined.dev` con texto: "Confirmo solicitud ARCO del {fecha}".
3. Si la solicitud se realiza a través de un representante, requiere lo previsto por el Art. 89 del Reglamento de la LFPDPPP: identificación oficial vigente del titular **y** del representante, más uno de los siguientes instrumentos que acrediten la representación:
   - Carta poder firmada ante **dos testigos** (anexando identificación oficial de ambos testigos), o
   - Instrumento público (poder notarial).
   La carta poder simple sin testigos no es suficiente para validar la representación.

Si no se acredita identidad razonablemente, niega la solicitud documentando el motivo. Conserva la negativa por el plazo de retención de bitácoras.

## 3. Acción según el derecho ejercido

### Acceso
- Genera y envía al titular un archivo (CSV o JSON) con todos sus datos personales tratados: identificación, autenticación (hash, nunca contraseña en claro), patrimoniales (trades, alertas, observaciones), técnicos operativos.
- Indica el origen de cada categoría de dato (capturado por el usuario vs derivado/agregado por el sistema).

### Rectificación
- Aplica el cambio solicitado directamente sobre la cuenta. Para datos derivados (por ejemplo, cálculos de portafolio), explica que se actualizan automáticamente al modificar los datos de entrada.
- Notifica también al encargado de envío de correo si el cambio afecta su listado (p. ej. cambio de correo o nombre).

### Cancelación
- Si la solicitud abarca toda la cuenta: ejecuta el flujo de cancelación de cuenta — borra datos personales en máximo 30 días naturales, conserva sólo la bitácora mínima del ejercicio ARCO por el plazo legal aplicable.
- Si abarca datos parciales: borra los registros específicos. Documenta qué se borró y qué se mantuvo y por qué.

### Oposición
- Identifica la finalidad específica a la que se opone. Si es una finalidad necesaria para la prestación del servicio (operación de cuenta, seguridad), explica que el ejercicio del derecho impide la continuidad del servicio y ofrece la cancelación como alternativa.
- Si es una finalidad voluntaria (no aplicable hoy), aplica la oposición sin cancelar la cuenta.

### Revocación del consentimiento
- Equivalente operativo a oposición sobre todas las finalidades para las que se otorgó consentimiento expreso. Para datos patrimoniales (Art. 8 NLFPDPPP), la revocación implica detener su tratamiento y, salvo obligación legal de conservación, eliminarlos.

## 4. Respuesta al titular

Dentro de los 20 días hábiles, envía respuesta al correo desde el que llegó la solicitud (o al registrado, si la identidad se validó por ese medio). Incluye:

- Acuse del derecho ejercido y la decisión adoptada (procedente, parcialmente procedente o no procedente).
- Si es procedente: descripción de las acciones realizadas y, cuando aplique, archivo de datos o evidencia del cambio.
- Si es parcial o negativa: motivación legal específica.
- Recordatorio de que tiene derecho a presentar denuncia ante la autoridad mexicana competente en protección de datos personales si está inconforme.
- Firma del responsable (Adrian Castillo).

Plantilla de correo: ver `docs/ops/arco-response-template.md` (pendiente; usa este documento como referencia hasta entonces).

## 5. Bitácora interna

Para cada solicitud ARCO, registra en bitácora interna (puede ser un repo privado o un documento cifrado):

| Campo | Contenido |
|---|---|
| `id` | Identificador secuencial |
| `received_at` | Fecha y hora de recepción |
| `requester_email` | Correo del solicitante |
| `right` | acceso / rectificación / cancelación / oposición / revocación |
| `identity_validated_at` | Fecha en que se validó la identidad |
| `decision` | procedente / parcial / negativa |
| `decision_rationale` | Motivación |
| `actions_taken` | Descripción de las acciones |
| `responded_at` | Fecha de respuesta |
| `clock_days` | Días hábiles transcurridos entre recepción y respuesta |

Conserva esta bitácora por el plazo establecido por la legislación aplicable. No incluye los datos personales del titular más allá del correo y la decisión.

## 6. Plazos críticos

| Hito | Plazo | Norma |
|---|---|---|
| Solicitud de información adicional para identidad | 5 días hábiles | Art. 32 NLFPDPPP |
| Respuesta al titular | 20 días hábiles | Art. 32 NLFPDPPP |
| Aplicación de la acción (cuando procede) | 15 días hábiles posteriores a la respuesta | Art. 32 NLFPDPPP |
| Eliminación de datos tras cancelación de cuenta | 30 días naturales | Aviso de privacidad vigente |

Si por causa justificada no es posible cumplir el plazo de respuesta, comunica al titular la prórroga (única, por igual periodo) antes del vencimiento del plazo original.

## 7. Coordinación con la cancelación de cuenta

Una solicitud de cancelación total equivale operativamente a la baja de la cuenta. Aplica el mismo flujo: confirmar identidad, deshabilitar acceso, programar borrado en 30 días naturales, mantener bitácora mínima.

Si la cuenta tiene operaciones recientes que el usuario podría querer exportar antes del borrado, ofrece el archivo de datos (acción de "Acceso") en la misma respuesta.

---

**Última revisión:** 2026-05-18. Mantén este documento alineado con `app/views/legal/privacy.html.erb` — si cambia alguno, revisa el otro.
