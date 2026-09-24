# Guía de la prueba de usabilidad con estudiantes piloto

**Para:** Ramon, Reyes y Rosario — los tres que van a correr las sesiones.

Esta prueba es la actividad de la **Fase IV** declarada en el Cuadro 2 del Capítulo 3: *"Aplicación de pruebas funcionales y de usabilidad con estudiantes"*, recurso *"Estudiantes piloto"*. Es la única actividad de la metodología que todavía no se ejecutó.

---

## Qué es, y qué no es

| ✅ Esto sí | ❌ Esto no |
|---|---|
| Ver si los estudiantes **pueden usar** el juego solos | Medir cuánto aprendieron |
| Anotar dónde se traban y qué no entienden | Comparar antes y después |
| Registrar si completan cada tarea | Calcular mejoras de conocimiento |

Con **4 estudiantes alcanza**. En usabilidad, con 5 usuarios se detecta la mayoría de los problemas de uso (Nielsen, 2000); es el estándar de la disciplina y por eso una muestra chica acá no es una debilidad, es lo correcto. Convendría decirlo así en el Capítulo 4 cuando escriban los resultados.

**Regla de oro:** ustedes **no ayudan**. Si el estudiante no encuentra algo, eso *es* el resultado. Solo intervienen si lleva más de 2 minutos trabado o si el juego se rompe.

---

## Antes de la sesión

- [ ] Una computadora con navegador y buen internet. **No sirve el celular**: el juego es de escritorio.
- [ ] La URL: **https://ereyes05.github.io/green-metric-urbe/juego/**
- [ ] Cada estudiante con **su propia cuenta**, creada por él en el momento (es la Tarea 1). El correo tiene que ser de un dominio aceptado: `urbe.edu`, `gmail.com`, `outlook.com`, `hotmail.com`, `yahoo.com` o `icloud.com`.
- [ ] **No hace falta que abran el correo.** Desde el 2026-09-24 el registro no manda ninguna confirmación: se llena el formulario y se entra. Si alguien se queda esperando un correo, es que algo se volvió a cambiar en Supabase — revisá [supabase_correos.md](supabase_correos.md).
- [ ] **Si alguno olvida su contraseña**, se la cambiás vos desde el panel de Supabase (*Authentication → Users*). En el juego no hay opción de recuperarla: está oculta a propósito, porque el correo no sale y la pantalla decía que sí.
- [ ] **Dos personas por sesión:** uno facilita (habla), otro observa y anota. No se puede hacer bien solo.
- [ ] Una planilla impresa por estudiante (está al final de esta guía).
- [ ] Reloj o cronómetro.
- [ ] **Anotar qué `user_id` es cada estudiante.** Después no hay forma de saberlo. En el documento se los nombra **E1, E2, E3, E4**; la lista con los nombres reales se guarda aparte y **no va en la tesis**.

**Duración estimada:** 35–45 minutos por estudiante.

---

## Guion del facilitador

Leelo casi textual. Sirve para que las 4 sesiones sean comparables.

> «Gracias por ayudarnos. Vamos a probar un juego que hicimos para aprender sobre sostenibilidad en la universidad.
>
> Lo importante es que **no te estamos evaluando a vos: estamos evaluando el juego**. Si algo no se entiende o no lo encontrás, es un problema nuestro, no tuyo. De hecho, eso es justo lo que necesitamos saber.
>
> Te voy a pedir que hagas algunas cosas. Mientras las hacés, **decí en voz alta lo que estás pensando**: qué estás buscando, qué esperabas que pasara, qué te confunde. Aunque te parezca obvio.
>
> No te voy a ayudar salvo que te trabes mucho, y no es por mala onda: si te ayudo, no me entero de dónde está el problema.
>
> ¿Alguna duda antes de empezar?»

Durante la sesión, si se queda callado, recordale: *«¿Qué estás pensando?»* · *«¿Qué esperabas que pasara?»*

Si pregunta *«¿está bien así?»*, devolvele la pregunta: *«¿Vos qué harías?»*

---

## Las tareas

Cada una dice qué pedirle, cómo saber si lo logró, y qué mirar. **Todas son alcanzables con una cuenta nueva** — eso está verificado.

Los controles del juego: **WASD o las flechas** para moverse, **E** para interactuar, **teclas 1 a 5** para la barra de abajo.
No se los digas: si el estudiante no los descubre, eso es un hallazgo.

### Tarea 1 — Entrar al juego · HU-001, HU-002

> «Entrá al juego y create una cuenta.»

**Se logró si:** llega al mapa del campus con su avatar.

**Mirá:** ¿entiende que tiene que registrarse y no iniciar sesión? ¿el mensaje de error del correo se entiende si pone uno de dominio no aceptado? ¿cuánto tarda?

**Miralo especialmente acá:** ¿encuentra **su carrera** en la lista? *Ingeniería en Informática* se agregó el 2026-09-24 y va primera — antes no estaba, así que los estudiantes del estudio tenían que anotarse como *Computación* o *Otra*. Si alguno duda o elige mal igual, eso es un hallazgo de la lista, no del estudiante.

### Tarea 2 — El tutorial · HU-003

> (No le digas nada. El tutorial aparece solo la primera vez.)

**Se logró si:** lo lee y llega al final.

**Mirá:** ¿lo lee o le da a "Siguiente" sin mirar? **Cronometrá cuántos segundos pasa en cada una de las 4 pantallas.** Si pasa 2 segundos en una pantalla de 4 líneas, no la leyó — y eso es un hallazgo importante, porque el tutorial es obligatorio justamente porque la Tabla 11 dice que el 65% lo prefiere así.

### Tarea 3 — Moverse y encontrar algo que hacer · HU-003, HU-010

> «Movete por el campus y encontrá algo para hacer. Avisame cuando encuentres tu primera misión.»

**Se logró si:** llega a un punto de misión y le aparece el cartel de interactuar.

**Mirá:** ¿descubre solo los controles? ¿en cuánto tiempo? ¿se choca con paredes invisibles? ¿entiende que la **E** sirve para interactuar? **Anotá el minuto exacto** en que encuentra la primera misión.

### Tarea 4 — Hablar con un NPC y responder el quiz · HU-004, HU-006

> «Hablá con alguno de los personajes del campus y hacé lo que te pida.»

**Se logró si:** completa un quiz, sea con aciertos o con errores.

**Mirá:** ¿entiende que hay un temporizador? ¿qué cara pone cuando falla? ¿entiende que puede reintentar? ¿lee la retroalimentación o la saltea? **Anotá cuántas preguntas acierta** — no para evaluarlo, sino para ver si el nivel de dificultad es razonable.

### Tarea 5 — Entender su progreso · HU-005, HU-011

> «Sin que yo te diga cómo: averiguá cuánto puntaje GreenMetric llevás y en qué puesto estás respecto de los demás.»

**Se logró si:** abre el Reporte (tecla 2) y el Ranking (tecla 3), o los botones de la barra de abajo.

**Mirá:** ¿descubre la barra de abajo? ¿usa las teclas o el mouse? ¿entiende qué significan las seis categorías del panel GreenMetric de la derecha? **Preguntale después: «¿qué te parece que significa ese 83?»**

### Tarea 6 — La tienda · HU-012

> «Entrá a la tienda y decime qué comprarías y por qué.»

**Se logró si:** abre la tienda (tecla 5) y explica qué le serviría.

**Ojo:** arranca con **50 EcoCredits** y lo más barato cuesta **60**, así que **no va a poder comprar nada**. Eso es a propósito en esta prueba. Lo que se observa es si **entiende por qué no puede** y si sabe qué tendría que hacer para conseguir más. Si se frustra o no entiende el mensaje, es un hallazgo.

### Tarea 7 — El simulador de decisiones · Tabla 7

> «Abrí el simulador y tomá una decisión.»

**Se logró si:** abre el simulador (tecla 4), elige una opción y ve el resultado.

**Mirá:** ¿entiende que es **práctica** y no cuenta para su puntaje? ¿lee la explicación de por qué una opción era mejor? Esta es la mecánica que la Tabla 13 dice que la experta priorizó, así que interesa especialmente.

---

## Después: el cuestionario

Dáselo apenas termine, antes de comentar nada. Es la **Escala de Usabilidad del Sistema (SUS)** de Brooke (1996), el instrumento estándar de la disciplina — citable y comparable.

Cada ítem se responde del **1 (muy en desacuerdo) al 5 (muy de acuerdo)**.

| # | Ítem |
|---|---|
| 1 | Creo que usaría este juego con frecuencia |
| 2 | Encontré el juego innecesariamente complejo |
| 3 | Me pareció fácil de usar |
| 4 | Creo que necesitaría ayuda de alguien para poder usarlo |
| 5 | Las distintas partes del juego están bien integradas |
| 6 | Me pareció que había demasiada inconsistencia en el juego |
| 7 | Imagino que la mayoría aprendería a usarlo muy rápido |
| 8 | Me resultó muy incómodo de usar |
| 9 | Me sentí seguro usando el juego |
| 10 | Necesité aprender muchas cosas antes de poder usarlo |

**Cómo se calcula el puntaje:**

1. En los ítems **impares** (1, 3, 5, 7, 9): restale 1 a la respuesta.
2. En los ítems **pares** (2, 4, 6, 8, 10): restale la respuesta a 5.
3. Sumá los diez resultados y **multiplicá por 2,5**.

Da un número de 0 a 100. **68 es el promedio de referencia**; por encima de 68 la usabilidad se considera aceptable.

> Con 4 estudiantes reporten los **cuatro puntajes individuales y el promedio**, y digan explícitamente que es un estudio exploratorio de usabilidad. **No calculen porcentajes** — con n=4, un porcentaje es engañoso.

Y dos preguntas abiertas al final, que suelen dar lo más valioso:

- ¿Qué fue lo **más confuso** del juego?
- Si pudieras cambiar **una sola cosa**, ¿cuál sería?

---

## Planilla de registro

Una por estudiante. Imprimila o copiala a mano.

```
ESTUDIANTE: E___        FECHA: ___/___/______      HORA INICIO: ______
user_id (del panel de Supabase): ______________________________________
FACILITA: ______________________  OBSERVA: ____________________________

┌──────────────────────────────┬────────┬────────┬──────────────────────┐
│ TAREA                        │ LOGRÓ  │ TIEMPO │ DÓNDE SE TRABÓ       │
├──────────────────────────────┼────────┼────────┼──────────────────────┤
│ 1. Crear cuenta y entrar     │ SÍ/NO  │        │                      │
│ 2. Tutorial (seg. x pantalla)│ __/__/__/__     │                      │
│ 3. Encontrar 1ª misión       │ SÍ/NO  │        │                      │
│ 4. NPC + quiz  (aciertos:__) │ SÍ/NO  │        │                      │
│ 5. Reporte y Ranking         │ SÍ/NO  │        │                      │
│ 6. Tienda (¿entendió el EC?) │ SÍ/NO  │        │                      │
│ 7. Simulador                 │ SÍ/NO  │        │                      │
└──────────────────────────────┴────────┴────────┴──────────────────────┘

DESCUBRIÓ SOLO LOS CONTROLES:   WASD/flechas [ ]    tecla E [ ]    barra 1-5 [ ]

FRASES TEXTUALES (anotá lo que diga, con sus palabras):
_______________________________________________________________________
_______________________________________________________________________
_______________________________________________________________________

PUNTAJE SUS: ______ / 100

LO MÁS CONFUSO: ______________________________________________________
SI PUDIERA CAMBIAR UNA COSA: _________________________________________
```

---

## Cómo se escribe después en el Capítulo 4

Una vez hechas las 4 sesiones, la Fase IV se documenta así:

1. **Qué se hizo:** cuántos estudiantes, cuándo, con qué tareas, en qué condiciones.
2. **Tabla de resultados por tarea:** cuántos de los 4 la completaron y el tiempo promedio.
3. **Tabla de puntajes SUS:** los cuatro individuales y el promedio, contra la referencia de 68.
4. **Los problemas encontrados**, ordenados por cuántos estudiantes los sufrieron. Un problema que le pasa a 3 de 4 es prioritario; uno que le pasa a 1 puede ser particular de esa persona.
5. **Qué se corrigió a partir de eso.** Este punto es el que cierra el ciclo de *"Inspección y Adaptación"* que promete el Cuadro 2 — sin él, la prueba queda a mitad de camino.

El punto 5 importa más de lo que parece: Scrum no es solo probar, es **probar y ajustar**. Si encuentran algo y lo arreglan, avisame y lo corregimos antes de que escriban esa parte.
