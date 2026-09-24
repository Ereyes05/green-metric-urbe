# Revisión de los cuatro capítulos

**Fecha:** 2026-09-24 · **Para:** Ramon, Reyes y Rosario — y para llevarle las dudas al tutor.

Se leyeron los cuatro capítulos y se cruzaron entre sí y contra el código. Los marcados **NO TOCAR** solo se leyeron. Nada de la carpeta `tesis` se copió al repositorio.

---

## 1. Lo más importante: dos objetivos específicos sin documentar

El **Capítulo 1** define seis objetivos específicos. El **Capítulo 4** documenta las **Fases I, II y III**, y cierra con *"queda construido el modelo físico del entorno virtual de aprendizaje"*.

| # | Objetivo específico (Cap. 1) | Fase | ¿Documentado en el Cap. 4? |
|---|---|---|---|
| 1 | Analizar el conocimiento previo y la percepción de los estudiantes | I | ✅ |
| 2 | Determinar los requerimientos funcionales | I | ✅ |
| 3 | Diseñar lógicamente el entorno virtual | II | ✅ |
| 4 | Construir el diseño físico a partir del modelo lógico | III | ✅ |
| 5 | **Validar el funcionamiento mediante pruebas técnicas** | IV | ❌ **No aparece** |
| 6 | **Explicar el funcionamiento a través del manual de usuarios** | V | ❌ **No aparece** |

**Esto es más grande que todo lo que estaba en la auditoría del Capítulo 4.** No es una tabla que promete algo y no se cumple: son **dos de los seis objetivos de la investigación** sin una sección que muestre cómo se cumplieron.

Y se enlaza con lo que ya sabíamos:

- **El objetivo 5 es la prueba de usabilidad.** El Cuadro 2 del Cap. 3 la detalla: *"pruebas funcionales y de usabilidad con estudiantes"*, recurso *"estudiantes piloto"*. Nunca se hizo. La guía para hacerla está en [guia_prueba_usabilidad.md](guia_prueba_usabilidad.md).
- **El objetivo 6 es el manual de usuarios.** Al 2026-09-24 hay un **borrador completo** en [manual_usuarios.md](manual_usuarios.md), verificado contra el código. Le faltan las 20 capturas, la revisión de alguien que haya jugado, y el formato de la universidad.

**Qué hacer:** son dos secciones nuevas al final del Capítulo 4, una por fase. La de la Fase IV se escribe con los resultados de la prueba de usabilidad; la de la Fase V, con el manual. **Consultarlo con el tutor antes de escribir**, porque puede que él espere que las fases IV y V vayan en un capítulo aparte y no dentro del 4.

> El manual de usuarios es trabajo nuevo, pero es el más acotado de los dos: el juego ya está terminado y funcionando, así que es documentar lo que hay. Se puede armar con capturas del juego publicado.

---

## 2. Capítulo 3 — estado de las correcciones

El equipo aplicó los cambios el 2026-09-24. No quedaron marcas de control de cambios sin resolver.

| # | Corrección | Estado |
|---|---|---|
| 1 | Cuadro 1: "Dos (20)" → "Veinte (20)" | ✅ Aplicada |
| 2 | Cuadro 2: lenguaje → "GDScript, SQL" | ⚠️ **A medias** |
| 3 | "aleatoriamente**.** quienes" → "aleatoriamente**,** quienes" | ❌ **Sin aplicar** |
| 4 | Frase del muestreo intencional de la experta | ✅ Aplicada |

### 2.1. El `JavaScript` que sigue ahí — error de mi revisión anterior

En el **Cuadro 2** quedó corregido a *"Lenguaje de programación (GDScript, SQL)"*. Pero **hay un segundo lugar que no señalé**: la sección **6.2 SOFTWARE**, al final del capítulo, que lista:

```
JavaScript
SQL
Visual Studio Code
```

Ahí sigue diciendo `JavaScript`, y sigue faltando `GDScript` y `Godot`. Es el mismo error en otro sitio, y yo solo marqué uno de los dos.

**Corregir a:** `GDScript`, `SQL`, `Godot`, `Visual Studio Code`.

Recordatorio del dato: el proyecto tiene **25.492 líneas de GDScript**, 1.962 de SQL, 154 de Python y **0 de JavaScript** escritas por el equipo.

### 2.2. La coma que faltó

Sigue estando *"...seleccionados aleatoriamente. quienes evaluarán..."* — punto de más y minúscula después. Es cosmético pero está a la vista.

---

## 3. Capítulo 2 ↔ Capítulo 3 — la tensión, ahora con el texto exacto

Esto ya estaba señalado, pero al leer el Capítulo 2 completo resultó **más marcado** de lo que parecía.

**Definición operacional (Cap. 2):**

> *"Esta relación se cuantifica mediante el monitoreo de la interacción del usuario con las dinámicas y componentes del juego y la posterior evaluación, mediante instrumentos de recolección de datos, del **incremento** en la autoeficacia y conciencia crítica del estudiante"*

**Diseño (Cap. 3):**

> *"la investigación se considera como de campo, **no experimental** y **transversal**"* · *"las variables... se recolectan en **un único momento**, sin ser alteradas intencionalmente"*

**El problema está en una palabra: "incremento".** Medir un incremento exige **dos mediciones** —antes y después—, y un diseño transversal mide **una sola vez**. Tal como están redactados, los dos capítulos piden cosas incompatibles.

**Salidas posibles** (la decisión es del equipo con el tutor):

- **La más simple:** cambiar *"del incremento en la autoeficacia y conciencia crítica"* por algo como *"del nivel de autoeficacia y conciencia crítica"*. Una palabra, y el diseño transversal deja de contradecirse.
- **La otra:** sostener el "incremento", pero entonces el Cap. 3 tendría que declarar un diseño pre-experimental con pre-test y post-test, y eso es rehacer el marco metodológico.

**Es una sola pregunta para el tutor**, y conviene hacerla antes de escribir las secciones de las Fases IV y V.

---

## 4. Capítulo 1 — coherente, y un dato de calendario

El Capítulo 1 está bien alineado: el problema, la pregunta, el objetivo general y los seis específicos son coherentes entre sí y con lo que el proyecto hizo. No se detectaron contradicciones con el código.

**El dato que importa para planificar:**

> *"se desarrolló en un lapso de tres (03) períodos académicos, comprendidos entre **enero y noviembre de 2026**, con una duración de once (11) meses"*

Estamos a **24 de septiembre**: quedan unos **dos meses**. Con dos objetivos específicos sin documentar, ese es el tiempo real disponible, y explica por qué conviene no abrir frentes nuevos.

---

## 5. Capítulo 4 — 16 de 18

Detalle completo en [auditoria_capitulo4.md](auditoria_capitulo4.md).

- **Tabla 1** (Responsive): el archivo `Capítulo 4 - CAMBIOS PROPUESTOS.docx` está en la carpeta de la tesis, con los cambios marcados y un comentario explicando cada uno. Falta aceptarlos.
- **Tabla 9** (microlearning): medida el 2026-09-24. Verificada a nivel misión; a nivel sesión hacen falta recorridos completos, que llegan con la prueba de usabilidad.

---

## Resumen: qué falta, en orden

| | Qué | Quién |
|---|---|---|
| 1 | **Preguntarle al tutor** las dos dudas: dónde van las Fases IV y V, y qué hacer con "incremento" en el Cap. 2 | Los tres |
| 2 | **Hacer la prueba de usabilidad** con los 4 estudiantes piloto → cierra el objetivo 5 y la Tabla 9 | Los tres |
| 3 | **Terminar el manual de usuarios** (borrador listo; faltan las 20 capturas y la revisión) → cierra el objetivo 6 | Los tres |
| 4 | Aceptar los cambios del `Capítulo 4 - CAMBIOS PROPUESTOS.docx` | El encargado del Cap. 4 |
| 5 | Corregir el `JavaScript` de la sección 6.2 y la coma del Cap. 3 | El encargado del Cap. 3 |

**Del lado del código no falta nada que la tesis exija.** Los cinco puntos de arriba son trabajo de documento y de sesiones con estudiantes.

---

## Apéndice: qué se hizo después de esta revisión (2026-09-24)

Nada de esto lo pedía un capítulo — salió de probar el juego — pero dos cosas habrían arruinado la sesión con los estudiantes:

- **El registro pedía confirmar por correo y el correo no llegaba.** El servicio de Supabase solo entrega a las direcciones del equipo del proyecto. Ningún estudiante habría podido entrar. Se apagó la confirmación: ahora se registran y entran.
- **Faltaba "Ingeniería en Informática"** en la lista de carreras — la población que el Cap. 3 define como muestra. Se habrían registrado todos con la carrera equivocada.
- Se ocultó *"¿Olvidaste tu contraseña?"*, que decía *"¡Código enviado!"* sin enviar nada.
- La descarga del juego bajó de 4,6 a 1,4 MB.

Detalle en [ESTADO_PROYECTO.md](ESTADO_PROYECTO.md), sección 12.
