# Procedimiento operativo ARCO

> Cómo procesar solicitudes de Acceso, Rectificación, Cancelación, Oposición (ARCO) y revocación de consentimiento, conforme a los Arts. 28-32 LFPDPPP (DOF 20-mar-2025).

> **Este documento describe lo que el operador puede hacer hoy, a mano.** No hay flujo de cancelación de cuenta en la app, no hay exportación de datos personales y no hay tooling ARCO: todo se ejecuta desde la consola de Rails de tu instancia. Las brechas están listadas sin adorno en la [§8](#8-brechas-conocidas). Si tu aviso de privacidad promete algo que la §8 marca como bloqueado, la obligación sigue siendo tuya y se cumple manualmente.

---

## 0. Quién es el responsable

Desde el pivote a self-hosted de una sola persona ([ADR-010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)), **no hay un responsable único del software**. El *responsable* en términos de la LFPDPPP es **quien opera cada instancia** y decide sobre el tratamiento de los datos que contiene:

| Instancia | Responsable | Contacto |
|---|---|---|
| `stockerly.notdefined.dev` | Adrian Castillo, persona física, CDMX | `support@notdefined.dev` |
| Cualquier despliegue self-hosted | Quien lo opera | El que publique en su propio aviso |

Si levantaste tu propia instancia: el aviso de privacidad que sirve la app (`app/views/legal/privacy.html.erb`) nombra a Adrian Castillo y su correo. **Ese texto no te aplica y debes reemplazarlo por tus propios datos antes de exponer la instancia a terceros.** Servirlo tal cual señala a un responsable que no controla tus datos.

En la práctica, una instancia de un solo usuario en la que el operador es también el titular no genera solicitudes ARCO: el titular ya tiene acceso total. Este procedimiento aplica cuando el operador y el titular son personas distintas.

## 1. Recepción de la solicitud

Las solicitudes llegan por correo a la dirección de contacto del responsable (`support@notdefined.dev` en la instancia de referencia).

> **No abras un issue en GitHub.** El repositorio es **público**: nombre, correo y el detalle de la solicitud quedarían publicados. No existe la etiqueta `arco` y no debe crearse. La bitácora va donde dice la [§6](#6-bitácora-interna): fuera del repo.

Registra en tu bitácora privada:

- Fecha y hora de recepción (UTC y hora local CDMX).
- Datos del solicitante (nombre, correo registrado).
- Derecho que ejerce (acceso, rectificación, cancelación, oposición o revocación).
- Descripción exacta de los datos sobre los que recae.

La fecha de recepción inicia el **plazo de 20 días hábiles** (Art. 32 LFPDPPP).

## 2. Validación de identidad

Antes de cualquier acción, valida que la persona que solicita es titular de los datos:

1. Verifica que el correo desde el que llega la solicitud coincide con el correo registrado en la cuenta.
2. Si hay duda razonable (correo distinto, lenguaje atípico, datos imprecisos), responde solicitando una prueba adicional en los primeros **5 días hábiles**:
   - Captura de pantalla del último correo transaccional recibido de Stockerly, o
   - Confirmación enviada desde el correo registrado con texto: "Confirmo solicitud ARCO del {fecha}".
3. Si la solicitud se realiza a través de un representante, requiere lo previsto por el Art. 89 del Reglamento de la LFPDPPP: identificación oficial vigente del titular **y** del representante, más uno de los siguientes instrumentos que acrediten la representación:
   - Carta poder firmada ante **dos testigos** (anexando identificación oficial de ambos testigos), o
   - Instrumento público (poder notarial).
   La carta poder simple sin testigos no es suficiente para validar la representación.

Si no se acredita identidad razonablemente, niega la solicitud documentando el motivo. Conserva la negativa por el plazo de retención de bitácoras.

## 3. Herramienta: la consola

Todo se hace desde la consola de Rails de la instancia. En el despliegue Kamal de referencia:

```bash
bin/kamal console
```

(Requiere las variables de entorno del deploy exportadas; ver [`deploy.md`](./deploy.md) §7.)

Ubica al titular una sola vez y reutiliza la variable:

```ruby
user = User.find_by!(email: "titular@ejemplo.com")
```

## 4. Acción según el derecho ejercido

### Acceso

**No existe exportación de datos personales en la app.** La única exportación CSV que ofrece la interfaz es la de bitácoras del sistema en `/admin/logs`, que no es un archivo de datos del titular. El archivo se arma a mano.

Desde la consola, reúne las categorías que el aviso de privacidad declara:

```ruby
payload = {
  identificacion: user.slice(:id, :full_name, :email, :created_at, :onboarded_at),
  autenticacion:  { email_verified_at: user.email_verified_at },
  patrimoniales:  {
    trades:     user.portfolio&.trades&.map(&:attributes),
    posiciones: user.portfolio&.positions&.map(&:attributes),
    snapshots:  user.portfolio&.snapshots&.map(&:attributes),
    dividendos: user.portfolio&.dividend_payments&.map(&:attributes)
  },
  alertas:        { reglas: user.alert_rules.map(&:attributes),
                    eventos: user.alert_events.map(&:attributes),
                    preferencias: user.alert_preference&.attributes },
  watchlist:      user.watchlist_items.map(&:attributes),
  notificaciones: user.notifications.map(&:attributes),
  operativos:     user.audit_logs.map(&:attributes)
}
puts JSON.pretty_generate(payload)
```

Copia la salida a un archivo, revísala antes de enviarla (**nunca incluyas `password_digest` ni `password_salt`**) y entrégala al titular.

Indica el origen de cada categoría: capturado por el usuario (trades, alertas, watchlist) vs derivado o agregado por el sistema (posiciones, snapshots, bitácoras).

> **Verifica el guion antes de usarlo.** El esquema cambia; una asociación renombrada hace que este bloque entregue un archivo incompleto sin fallar. Contrástalo con las asociaciones vigentes de `app/models/user.rb` y `app/models/portfolio.rb` en cada solicitud.

### Rectificación

Es el único derecho que se atiende sin fricción:

```ruby
user.update!(full_name: "Nombre corregido", email: "nuevo@ejemplo.com")
```

Para datos derivados (cálculos de portafolio), explica al titular que se recalculan automáticamente al modificar los datos de entrada; no se editan a mano.

Si cambia el correo o el nombre, notifica también al encargado de envío de correo (Resend) si conserva el dato en su listado.

### Cancelación

**No existe flujo de cancelación de cuenta en la app** — no hay ruta, ni caso de uso, ni botón. Está abierto como [issue #176](https://github.com/rodacato/stockerly/issues/176). Mientras tanto el borrado es manual, y **no basta con `user.destroy`**: `audit_logs` tiene llave foránea a `users` sin `dependent:` ni `on_delete: :cascade`, así que el destroy revienta con `ActiveRecord::InvalidForeignKey`. Lo mismo aplica a `site_config_changes.admin_id`.

Orden que sí funciona:

```ruby
ActiveRecord::Base.transaction do
  # Anota primero lo que la bitácora ARCO necesita conservar (§6):
  # después de estas dos líneas ya no se puede consultar.
  user.audit_logs.delete_all
  SiteConfigChange.where(admin_id: user.id).delete_all

  # El resto cae en cascada por `dependent: :destroy`: portfolio (trades,
  # posiciones, snapshots, dividendos), alert_preference, alert_rules,
  # alert_events, watchlist_items, notifications.
  user.destroy!
end
```

Después del borrado:

- Verifica que no quedaron huérfanos: `Portfolio.where(user_id: user_id).count` debe ser `0`.
- Conserva **sólo** la bitácora mínima del ejercicio ARCO de la §6, fuera de la base de datos.
- Recuerda que el aviso de privacidad promete el borrado en **máximo 30 días naturales**. Ese plazo corre aunque el flujo sea manual.

Si la solicitud abarca datos parciales y no la cuenta completa, borra los registros específicos (por ejemplo `user.portfolio.trades.where(...)`) y documenta qué se borró, qué se mantuvo y por qué.

### Oposición

- Identifica la finalidad específica a la que se opone. Si es una finalidad necesaria para la prestación del servicio (operación de cuenta, seguridad), explica que el ejercicio del derecho impide la continuidad del servicio y ofrece la cancelación como alternativa.
- Si es una finalidad voluntaria (no aplicable hoy: la app no trata datos para mercadotecnia, perfilamiento ni terceros), aplica la oposición sin cancelar la cuenta.
- No hay mecanismo de bloqueo parcial en la app. Si necesitas suspender el acceso sin borrar, `user.update!(status: :suspended)` es lo que existe, y es una medida operativa, no el cumplimiento del derecho por sí sola.

### Revocación del consentimiento

Equivalente operativo a oposición sobre todas las finalidades para las que se otorgó consentimiento expreso. Para datos patrimoniales (Art. 8 LFPDPPP), la revocación implica detener su tratamiento y, salvo obligación legal de conservación, eliminarlos — es decir, el mismo procedimiento manual de **Cancelación**.

## 5. Respuesta al titular

Dentro de los 20 días hábiles, envía respuesta al correo desde el que llegó la solicitud (o al registrado, si la identidad se validó por ese medio). Incluye:

- Acuse del derecho ejercido y la decisión adoptada (procedente, parcialmente procedente o no procedente).
- Si es procedente: descripción de las acciones realizadas y, cuando aplique, archivo de datos o evidencia del cambio.
- Si es parcial o negativa: motivación legal específica.
- Recordatorio de que tiene derecho a presentar denuncia ante la autoridad mexicana competente en protección de datos personales si está inconforme.
- Firma del responsable de la instancia (ver §0).

No hay plantilla de correo en el repo. Redáctala a partir de esta lista.

## 6. Bitácora interna

Para cada solicitud ARCO, registra en bitácora **fuera del repositorio público** — un repo privado, un documento cifrado, o notas locales:

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

## 7. Plazos críticos

| Hito | Plazo | Norma |
|---|---|---|
| Solicitud de información adicional para identidad | 5 días hábiles | Art. 32 LFPDPPP |
| Respuesta al titular | 20 días hábiles | Art. 32 LFPDPPP |
| Aplicación de la acción (cuando procede) | 15 días hábiles posteriores a la respuesta | Art. 32 LFPDPPP |
| Eliminación de datos tras cancelación de cuenta | 30 días naturales | Aviso de privacidad vigente |

Si por causa justificada no es posible cumplir el plazo de respuesta, comunica al titular la prórroga (única, por igual periodo) antes del vencimiento del plazo original.

## 8. Brechas conocidas

Lo que el aviso de privacidad promete y el código todavía no sostiene. Nada de esto exime al responsable: se cumple a mano, con el costo y el riesgo de error que eso implica.

| Brecha | Estado | Mitigación de hoy |
|---|---|---|
| No hay flujo de cancelación de cuenta en la app (sin ruta, sin caso de uso) | Abierto — [#176](https://github.com/rodacato/stockerly/issues/176) | Borrado manual por consola, §4 |
| `user.destroy` falla por la FK de `audit_logs` (sin `dependent:` ni cascada) | Sin issue | Borrar `audit_logs` y `site_config_changes` antes, §4 |
| No hay exportación de datos personales del titular | Sin issue | Armar el JSON a mano, §4 |
| No hay plantilla de respuesta ARCO | Sin issue | Redactar con la lista de la §5 |
| El aviso de privacidad codifica un responsable fijo, no al operador de cada instancia | Sin issue | Editar `app/views/legal/privacy.html.erb` al desplegar, §0 |

---

**Última revisión:** 2026-08-27. Mantén este documento alineado con `app/views/legal/privacy.html.erb` — si cambia alguno, revisa el otro. Cuando #176 cierre, reescribe la §4 "Cancelación" y borra su renglón de la §8.
