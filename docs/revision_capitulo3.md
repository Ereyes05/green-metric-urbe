# Revisión del Capítulo 3 (Marco Metodológico)

**Fecha:** 2026-09-23 · **Para:** Ramon, Reyes y Rosario — y para llevarle las dudas al tutor.

El archivo está marcado **NO TOCAR**: solo se leyó. No se modificó nada ni se copió al repositorio.

Se revisó contra dos cosas: el Capítulo 4 (que ya estaba auditado en [auditoria_capitulo4.md](auditoria_capitulo4.md)) y el código que realmente existe.

---

## 1. El hallazgo que cambia una prioridad

El Cuadro 2, en la **Fase IV**, compromete esto:

> *"Aplicación de pruebas funcionales y de **usabilidad con estudiantes**"* · Recurso: *"**Estudiantes piloto**"*

**Las sesiones con estudiantes no son opcionales: están declaradas en la metodología.** Si el Capítulo 3 dice que se harán pruebas de usabilidad con estudiantes piloto y no se hacen, queda una actividad metodológica sin ejecutar, y eso es de las cosas que un jurado revisa primero.

**Pero ojo con qué tipo de prueba es.** Dice *funcionales y de usabilidad*, no *medición del aprendizaje*. Eso cambia por completo lo que hay que recolectar:

| | Qué evidencia hace falta |
|---|---|
| ✅ Lo que pide el Cap. 3 | Que los estudiantes **usen** el juego y se registre si pudieron: dónde se trabaron, qué no entendieron, si completaron las tareas. Notas de observación o un cuestionario corto de usabilidad. |
| ❌ Lo que NO pide | Medir cuánto aprendieron, comparar antes y después, calcular mejoras. |

Con 3 o 4 estudiantes **alcanza de sobra** para una prueba de usabilidad: es lo habitual en ingeniería de software, donde con 5 usuarios se detecta la mayoría de los problemas de uso.

La tabla `eventos_aprendizaje` **no es la evidencia de esto**. Sirve para demostrar que el sistema registra la interacción, pero la prueba de usabilidad se documenta con lo que observás durante la sesión.

---

## 2. Una tensión entre el Capítulo 2 y el Capítulo 3

Esto conviene consultarlo con el tutor antes de tocar nada.

**El Capítulo 3 define el diseño como no experimental y transversal:**

> *"las variables de empoderamiento estudiantil y percepción de los indicadores ambientales se recolectan en un único momento, sin ser alteradas intencionalmente"*
>
> *"el cuestionario... se aplicará a la muestra de estudiantes de Informática en un único momento, estableciendo la línea base diagnóstica"*

**El Capítulo 2 define operacionalmente el empoderamiento así:**

> *"mediante el monitoreo de la interacción del usuario con las dinámicas y componentes del juego"*

Las dos frases no apuntan al mismo lado. Un diseño transversal mide **una vez**, con un cuestionario, para diagnosticar. Monitorear la interacción con el juego es seguimiento **a lo largo del uso**, que es lo que haría un diseño longitudinal o cuasi-experimental.

**La pregunta que puede llegar en la defensa:** *"¿Cómo midieron ustedes el empoderamiento estudiantil: con la encuesta diagnóstica, o con el monitoreo de la interacción?"*

**Posibles salidas** (la decisión es de ustedes y del tutor):

- **La más simple:** ajustar la definición operacional del Cap. 2 para que hable del cuestionario aplicado a la muestra, que es lo que el diseño del Cap. 3 efectivamente hace, y presentar el monitoreo como una **capacidad del sistema entregado**, no como el instrumento de medición.
- **La otra:** sostener el monitoreo como instrumento, pero entonces el Cap. 3 tendría que declararlo entre las técnicas de recolección, y el diseño transversal deja de encajar.

La primera es mucho menos trabajo y no obliga a rehacer el marco metodológico.

---

## 3. Errores concretos, verificables

Estos no son opinión: se comprueban abriendo el documento o el repositorio.

### 3.1. Cuadro 1 dice "Dos (20)"

| CARGO | CANTIDAD |
|---|---|
| Estudiante | **Dos (20)** ← |
| Directora del departamento de sustentabilidad | Uno (1) |

Debería decir **"Veinte (20)"**. El número entre paréntesis es correcto y coincide con el párrafo de la muestra; lo que está mal es la palabra.

### 3.2. El lenguaje de programación no es el que dice

El Cuadro 2 lista como recurso: *"Lenguaje de programación (**JavaScript**, **python**, SQL)"*.

Lo que hay en el repositorio, contado hoy:

| Lenguaje | Archivos | Líneas |
|---|---|---|
| **GDScript** (`.gd`) | 90 | **25.492** |
| SQL | 13 | 1.962 |
| Python | 1 | 154 |
| JavaScript | 0 | **0** |

El juego está escrito en **GDScript**, el lenguaje de Godot, y no aparece en el cuadro. JavaScript no se escribió nunca (el `index.js` del build lo genera Godot solo). Python son 154 líneas de un script de exportación.

Es un dato que cualquiera verifica abriendo el proyecto. **Corregirlo a "GDScript (Godot) y SQL"** es una línea.

### 3.3. Revisar que los otros recursos sean ciertos

El mismo Cuadro 2 lista *"Herramientas de gestión de proyectos (**Jira**)"* y *"**Software de análisis estadístico**"*. Si no usaron Jira, o si las tablas de frecuencias las hicieron en Word o Excel, conviene ajustarlo: son afirmaciones fáciles de cuestionar y no aportan nada al trabajo.

### 3.4. Erratas de redacción

- En la validez del instrumento: *"...seleccionados aleatoriamente**. q**uienes evaluarán..."* — punto de más y minúscula después.
- La misma frase dice que el instrumento se valida *"a través del Juicio de un experto en la sustentabilidad **y estudiantes seleccionados aleatoriamente**"*. El juicio de expertos es una técnica de validación reconocida; incluir estudiantes como validadores del instrumento es inusual, porque no son expertos en la materia que se valida. Si lo que hicieron fue una prueba piloto del cuestionario con estudiantes, conviene llamarlo así: **prueba piloto**, que sí es una técnica estándar y distinta del juicio de expertos.

### 3.5. Imprecisión en el muestreo

El Cap. 3 declara un **muestreo probabilístico aleatorio simple**, donde *"todos los elementos de la población tienen la misma probabilidad de ser seleccionados"*. Pero la población incluye *"los expertos o docentes involucrados en la validación"*, y a la Directora del Departamento de Sustentabilidad, obviamente, no se la eligió al azar: se la eligió por su cargo.

Eso es un **muestreo intencional o por conveniencia**, y es perfectamente válido — solo hay que nombrarlo. Lo más limpio es decir que se usaron dos muestras: una aleatoria simple de 20 estudiantes, y una intencional de 1 experta seleccionada por su rol institucional.

### 3.6. La Fase V describe el libro, no el proyecto

Los dos párrafos de la Fase V están redactados en términos genéricos de Kendall & Kendall: *"el analista trabaja con los programadores"*, *"un programador puede llevar a cabo un recorrido por el diseño"*. Describen la teoría, no lo que ustedes hicieron.

No es un error, pero un tutor puede pedir que se aterrice: qué documentación produjeron ustedes, con qué herramientas, y dónde está.

---

## 4. Lo que está bien y conviene no tocar

- El **tipo descriptivo y proyectivo** encaja con lo que hicieron: diagnosticaron y construyeron una propuesta. La cita de Hurtado sobre investigación proyectiva es la correcta para un trabajo que entrega un sistema.
- Las **cinco fases** del Cap. 3 se corresponden una a una con las del Cap. 4. Eso es coherencia interna, y es de lo primero que se revisa.
- El **diseño de campo** está bien justificado: los datos salen de los estudiantes de la URBE.
- Las citas están completas, con autor, año y página.

---

## 5. Qué haría yo, en orden

1. **Corregir "Dos (20)" → "Veinte (20)".** Treinta segundos, y es un error visible en un cuadro.
2. **Corregir el lenguaje de programación a GDScript.** Es verificable abriendo el repositorio.
3. **Llevarle al tutor la tensión Cap. 2 ↔ Cap. 3** (punto 2 de este informe). Es la única cuestión de fondo, y no es de ustedes decidirla solos.
4. **Planificar la prueba de usabilidad con estudiantes piloto**, que es una actividad declarada en la metodología y todavía no se ejecutó. Con 4 estudiantes alcanza.
5. Las erratas y la precisión del muestreo, cuando haya tiempo.

> Los puntos 1, 2, 4 y 5 son correcciones puntuales. El punto 3 es el único que puede requerir mover texto de fondo, y por eso conviene preguntarlo antes de escribir nada.
