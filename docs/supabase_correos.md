# Correos de Supabase — plantillas y configuración

**Proyecto:** `ikohikbpvtbvsgyumvbr` · **Última revisión:** 2026-09-24

> ## Estado actual: los correos están fuera de servicio, a propósito
>
> El **2026-09-24 se apagó la confirmación por correo** (`Confirm email` en *Authentication → Sign In / Providers → Email*). El estudiante se registra y entra directo. Verificado en `/auth/v1/settings`: `mailer_autoconfirm = true`.
>
> **Por qué:** el servicio de correo que Supabase trae de fábrica **solo entrega a las direcciones del equipo del proyecto** y admite **2 mensajes por hora** para todo el proyecto. A los estudiantes no les llegaba nada — ni se notaba, porque la pantalla decía que sí se había enviado.
>
> **Consecuencia:** la recuperación de contraseña **tampoco funciona** y muestra *"¡Código enviado!"* igual. Se resuelve a mano: *Authentication → Users* → cambiar la contraseña del estudiante.
>
> Lo de abajo (plantillas y Site URL) queda escrito para cuando se contrate un servicio de correo externo. **Hasta entonces no se puede aplicar**: Supabase no deja editar las plantillas sin SMTP propio.

Esto vive **solo en el panel de Supabase**, no en el código. Se guarda acá porque si alguien lo cambia o se pierde, no hay de dónde recuperarlo — y porque cuando está mal, el juego no lo puede arreglar desde su lado.

---

## Por qué existe este archivo

El 2026-09-24 la recuperación de contraseña estaba **rota en producción**.

El juego pide un **código de 6 dígitos** (`SupabaseManager.verificar_codigo_recuperacion` llama a `/auth/v1/verify` con `type=recovery` y `token=<código>`). La plantilla de correo que Supabase trae de fábrica **no muestra ese código**: manda un enlace. Y al pulsar el enlace, el código se consume, así que después ya no sirve.

Encima el enlace apuntaba a `http://localhost:3000`, que es el valor de ejemplo de fábrica, así que terminaba en `ERR_CONNECTION_REFUSED`.

**Regla para el futuro:** si el juego pide un código, la plantilla tiene que mostrar `{{ .Token }}`. Si la plantilla manda un enlace, el juego tendría que aceptar el enlace. Las dos cosas a la vez no funcionan.

---

## 1. URL Configuration

**Authentication → URL Configuration**
https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/auth/url-configuration

| Campo | Valor |
|---|---|
| **Site URL** | `https://ereyes05.github.io/green-metric-urbe/juego/` |

Esto es a dónde vuelve el estudiante después de confirmar su cuenta al registrarse.

> **Ojo con el registro:** aunque el Site URL esté mal, **la cuenta igual queda confirmada** — Supabase la confirma en su servidor *antes* de redirigir. Lo único que falla es la pantalla final. Por eso el registro "funcionaba" con `localhost:3000` y nadie se dio cuenta.

---

## 2. Plantilla: Reset Password

**Authentication → Emails → Reset Password**
https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/auth/templates

**Asunto:** `Tu código para recuperar la contraseña`

```html
<h2>Recuperar tu contraseña</h2>
<p>Tu código para <b>URBE Rangers: Eco-Quest</b> es:</p>
<p style="font-size:32px;letter-spacing:6px;font-weight:bold;font-family:monospace">{{ .Token }}</p>
<p>Escribilo en el juego, en la pantalla <b>Recuperar Contraseña</b>.</p>
<p>El código vence en una hora. Si no pediste esto, ignorá este correo.</p>
```

**No debe llevar enlace.** Si lo lleva, el estudiante lo pulsa, el código se consume y la recuperación falla con `otp_expired`.

---

## 3. Plantilla: Confirm signup

**Authentication → Emails → Confirm signup**

Esta **sí** usa enlace, y está bien así: el juego no pide código para confirmar la cuenta.

```html
<h2>Confirmá tu cuenta</h2>
<p>¡Bienvenido a <b>URBE Rangers: Eco-Quest</b>!</p>
<p>Pulsá acá para activar tu cuenta y poder entrar al juego:</p>
<p><a href="{{ .ConfirmationURL }}">Confirmar mi cuenta</a></p>
<p>Si no te registraste, ignorá este correo.</p>
```

---

## 4. Límite de envíos — importante para la prueba con estudiantes

El correo lo manda el servicio propio de Supabase, que es **para desarrollo** y tiene un tope bajo de envíos por hora. No avisa: simplemente el correo no llega.

**Authentication → Rate Limits**
https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/auth/rate-limits

Ahí se ve el número exacto vigente.

**Esto ya no afecta al registro**, porque desde el 2026-09-24 el registro no manda ningún correo (ver el recuadro del principio). Sigue afectando a cualquier cosa que sí use correo, o sea hoy solo la recuperación de contraseña.

Con un SMTP propio el tope sube a 30 registros por hora y los mensajes llegan a cualquier dirección, no solo a las del equipo. Se configura en **Authentication → Emails → SMTP Settings**, y recién ahí se destraban las plantillas de más arriba.

---

## Cómo comprobar que quedó bien

1. En el juego, **¿Olvidaste tu contraseña?** → poner un correo real → **Enviar código**.
2. El correo que llega tiene que traer **6 dígitos a la vista**, y ningún botón que invite a pulsar.
3. Escribir esos 6 dígitos en el juego → **Verificar código**.
4. Poner una contraseña nueva → **Cambiar contraseña**.
5. Entrar con la contraseña nueva.

Si el paso 3 dice *"Código incorrecto o vencido"*, revisar que la plantilla tenga `{{ .Token }}` y **no** un enlace.

> No repetir el paso 1 muchas veces seguidas: se choca con el límite de envíos y después parece que el arreglo no funcionó, cuando el problema es otro.
