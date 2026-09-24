# BORRADOR — Manual de usuarios

## URBE Rangers: Eco-Quest

### Entorno virtual de aprendizaje gamificado para el empoderamiento estudiantil en los indicadores UI GreenMetric

**Universidad Dr. Rafael Belloso Chacín (URBE)** · Maracaibo, Venezuela
**Estado:** 🚧 **BORRADOR — no entregar en esta forma**
**Versión:** 0.1 · **Fecha:** 2026-09-24
**Dirigido a:** estudiantes usuarios del sistema y al personal docente o administrativo que lo supervise.

---

> ## 🚧 Esto es un borrador
>
> **No es el manual terminado.** Es una base sobre la que trabajar, y le falta lo siguiente antes de que se pueda entregar:
>
> 1. **Las 20 capturas de pantalla.** Están marcadas `[CAPTURA 1]` … `[CAPTURA 20]`, y cada una dice qué debe mostrar. Se toman abriendo el juego publicado, con la herramienta **Recortes** de Windows.
> 2. **La revisión del equipo.** El texto lo redactó el asistente a partir del código fuente, no de haber jugado el juego como estudiante. Puede haber cosas que en la práctica se entiendan distinto.
> 3. **El formato final** que pida la universidad: portada, numeración, tipografía, y pasarlo a Word o PDF.
> 4. **Borrar este recuadro y el encabezado "BORRADOR"** cuando lo anterior esté hecho.
>
> **Qué sí está resuelto:** el contenido está **verificado contra el código**, no escrito de memoria. Los precios de la tienda salen de `sql/tienda_ecocredits.sql`; las insignias, de `sql/insignias_1_migracion.sql` y `sql/insignias_3_compras.sql`; los niveles y sus misiones, de `autoload/NivelManager.gd`; los rangos, de `autoload/rangos.gd`; los controles, del mapa de entradas de `project.godot`.
>
> **Para qué sirve:** cubre el **objetivo específico 6** del Capítulo 1 — *"Explicar el funcionamiento del modelo pedagógico gamificado a través del manual de usuarios"* (Fase V) —, que hasta ahora no tenía ningún documento que lo respaldara.

---

## Índice

1. [Qué es el sistema](#1-qué-es-el-sistema)
2. [Requisitos para usarlo](#2-requisitos-para-usarlo)
3. [Cómo entrar: registro e inicio de sesión](#3-cómo-entrar-registro-e-inicio-de-sesión)
4. [La primera vez: el tutorial](#4-la-primera-vez-el-tutorial)
5. [La pantalla del juego](#5-la-pantalla-del-juego)
6. [Controles](#6-controles)
7. [Las actividades de aprendizaje](#7-las-actividades-de-aprendizaje)
8. [Los seis niveles](#8-los-seis-niveles)
9. [El puntaje GreenMetric del campus](#9-el-puntaje-greenmetric-del-campus)
10. [Recompensas: EcoCredits, rangos e insignias](#10-recompensas-ecocredits-rangos-e-insignias)
11. [La Tienda del Conocimiento](#11-la-tienda-del-conocimiento)
12. [El ranking](#12-el-ranking)
13. [Guardado del progreso](#13-guardado-del-progreso)
14. [Solución de problemas](#14-solución-de-problemas)
15. [Para el docente o supervisor](#15-para-el-docente-o-supervisor)
16. [Glosario](#16-glosario)

---

## 1. Qué es el sistema

**URBE Rangers: Eco-Quest** es un videojuego educativo que se ejecuta en el navegador web. El estudiante controla a un *Eco-Ranger*: un personaje que recorre una representación del campus de la URBE, conversa con los coordinadores de cada área, responde cuestionarios y ejecuta acciones de mejora ambiental.

El propósito no es entretener. Es que el estudiante **conozca y comprenda los seis módulos del ranking UI GreenMetric** —el sistema mundial que evalúa la sostenibilidad de las universidades— viendo cómo cada decisión suya cambia el puntaje del campus.

El juego se estructura en **seis niveles**, uno por cada módulo del ranking:

| Nivel | Módulo UI GreenMetric | Icono |
|---|---|---|
| 1 | Infraestructura y Entorno | 🌿 |
| 2 | Energía y Cambio Climático | ⚡ |
| 3 | Manejo de Residuos | ♻ |
| 4 | Uso del Agua | 💧 |
| 5 | Transporte Sostenible | 🚲 |
| 6 | Educación e Investigación | 📚 |

Cada nivel se desbloquea al completar el anterior.

---

## 2. Requisitos para usarlo

El juego **no se instala**. Se abre desde el navegador.

| Requisito | Detalle |
|---|---|
| **Dirección** | https://ereyes05.github.io/green-metric-urbe/juego/ |
| **Navegador** | Google Chrome, Microsoft Edge, Firefox u Opera, en una versión de los últimos dos años. |
| **Conexión** | Permanente. El progreso se guarda en un servidor, no en la computadora. |
| **Descarga inicial** | Aproximadamente 41 MB la primera vez. Después el navegador reutiliza casi todo: en los ingresos siguientes solo baja 1,4 MB. |
| **Dispositivo** | Computadora de escritorio, portátil, tableta o teléfono. En pantalla táctil aparecen controles en pantalla automáticamente. |
| **Correo electrónico** | Necesario para registrarse, pero **no hay que abrirlo**: no se envía ninguna confirmación. No hace falta correo institucional (ver 3.1). |

> **Sobre la primera carga.** Al abrir la dirección aparece una barra de progreso. En una conexión lenta puede tardar uno o dos minutos. No es un bloqueo: es la descarga del juego.

**[CAPTURA 1]** — La pantalla de carga con la barra de progreso, recién abierta la dirección.

---

## 3. Cómo entrar: registro e inicio de sesión

Al terminar la carga aparece la pantalla de acceso.

**[CAPTURA 2]** — Pantalla de inicio de sesión completa, con los campos de correo y contraseña y los botones.

### 3.1. Registrarse (solo la primera vez)

1. Pulsar **Crear cuenta**.
2. Llenar el formulario:

| Campo | Qué se escribe |
|---|---|
| **Nombre completo** | Nombre y apellido del estudiante. Es el que aparece en el ranking. |
| **Cédula** | Número de cédula. **No se muestra a nadie más**: solo sirve para identificar al estudiante internamente. |
| **Correo electrónico** | Un correo válido y de un dominio permitido. Será el usuario para entrar. |
| **Carrera** | Se elige de la lista. **Ingeniería en Informática** es la primera opción. |
| **Trimestre** | Se elige de la lista. |
| **Contraseña** | Mínimo seis caracteres. |
| **Confirmar contraseña** | La misma contraseña, otra vez. |

3. Pulsar **Registrarme**.

**Eso es todo: se entra al juego de una vez.** No hay que confirmar nada por correo ni esperar ningún mensaje.

### Qué correos se aceptan

No hace falta tener un correo institucional. Se acepta cualquiera de estos dominios:

`urbe.edu` · `gmail.com` · `outlook.com` · `hotmail.com` · `yahoo.com` · `icloud.com`

> **Si el correo es rechazado**, el formulario lo avisa antes de enviarlo e indica cuáles dominios se aceptan. No es un error del sistema: es una restricción para que no se registren correos inventados. La lista se valida **dos veces**: en el formulario, para dar un mensaje claro, y otra vez en el servidor, para que no se pueda saltar.

**[CAPTURA 3]** — El formulario de registro con todos los campos visibles.

### 3.2. Iniciar sesión

1. Escribir el correo y la contraseña registrados.
2. Pulsar **Entrar**.

Si los datos son correctos, el juego carga el progreso guardado y lleva directamente al campus, en el punto donde se dejó la última vez.

### 3.3. Si se olvidó la contraseña

**Avisarle al docente o responsable de la actividad**, que la cambia en el momento. No hay que hacer ningún trámite.

En el juego no aparece ninguna opción de recuperar la contraseña: está oculta a propósito mientras no haya un servicio de correo (ver la nota de abajo).

> **Nota para el equipo — borrar antes de entregar.**
> La pantalla *"¿Olvidaste tu contraseña?"* existe en el juego y está programada, pero **hoy no funciona para los estudiantes** y peor: dice *"¡Código enviado!"* aunque no se haya enviado nada. El correo lo manda el servicio interno de Supabase, que solo entrega a las direcciones del equipo del proyecto y admite 2 mensajes por hora.
> Para que funcione hay que contratar un servicio de correo externo. Detalle y pasos en [supabase_correos.md](supabase_correos.md).
> **Mientras tanto se resuelve a mano:** panel de Supabase → *Authentication → Users* → buscar al estudiante → cambiar la contraseña. Diez segundos.

---

## 4. La primera vez: el tutorial

En el primer ingreso aparece una introducción de **cuatro pantallas**, que se lee pulsando **Siguiente**. No se puede saltar: explica lo mínimo necesario para jugar y para entender qué es GreenMetric.

| Paso | Contenido |
|---|---|
| 1 🌿 | Quién es el Eco-Ranger y cuál es su misión en el campus. |
| 2 📊 | Qué es UI GreenMetric y cuáles son sus seis módulos. |
| 3 🕹️ | Cómo moverse e interactuar, en computadora y en teléfono. |
| 4 🏛️ | La primera misión: ir al Rectorado y hablar con el Rector Morales. |

El tutorial aparece **una sola vez por cuenta**. A partir del segundo ingreso, el juego arranca directamente en el campus.

Después del tutorial, lo demás se enseña solo: cuando el estudiante se acerca por primera vez a algo nuevo, aparece un globo de ayuda explicando qué hacer.

**[CAPTURA 4]** — El primer paso del tutorial.
**[CAPTURA 5]** — El segundo paso, con la lista de los seis módulos GreenMetric.

---

## 5. La pantalla del juego

**[CAPTURA 6]** — El campus con el HUD completo visible. Es la captura más importante del manual: conviene que se vean los cuatro elementos a la vez.

La pantalla tiene cuatro zonas de información:

### 5.1. Ficha del jugador (arriba a la izquierda)

Muestra, de arriba abajo:

- **Eco-Ranger** y el nombre del estudiante
- **Nivel actual** (por ejemplo, *Nivel 1/6 · Entorno*)
- **Rango** alcanzado (*Semilla*, *Brote*, *Árbol*…) y una barra de avance con el texto *Hacia \<siguiente rango\>*
- **EcoCredits** disponibles

### 5.2. Panel GreenMetric (arriba a la derecha)

Es el corazón educativo de la interfaz. Muestra el **puntaje del campus de 0 a 100** y, debajo, una fila por cada uno de los seis módulos.

Cada fila tiene una barra dividida en cuatro tramos de distinto tono, que corresponden a las cuatro maneras de sumar puntos:

| Tramo | Significa | Máximo |
|---|---|---|
| Misiones | Completar las misiones del nivel | 80 |
| Quiz | Responder bien el cuestionario al primer intento | 10 |
| Decisiones | Elegir bien en los momentos de decisión | 5 |
| Sinergias | Acciones de otros niveles que también benefician a este | 5 |

Al pasar el cursor sobre una fila aparece el desglose: cuánto hay en cada tramo y qué falta hacer para subirlo.

> **Por qué importa este panel.** Es lo que convierte el juego en una herramienta de aprendizaje y no en un pasatiempo: el estudiante ve, en el mismo momento en que actúa, cómo su decisión mueve un indicador real del ranking mundial.

**[CAPTURA 7]** — El panel GreenMetric, y si es posible, otra con el desglose abierto al pasar el cursor por una fila.

### 5.3. Barra de acciones (abajo)

Cinco botones. Cada uno tiene también un atajo de teclado:

| Tecla | Botón | Para qué sirve |
|---|---|---|
| **1** | 🌡 Avance | Mapa de avance del campus |
| **2** | 📊 Reporte | Reporte GreenMetric detallado |
| **3** | 🏆 Ranking | Tabla de clasificación de todos los jugadores |
| **4** | 🔬 Simular | Simulador de decisiones |
| **5** | 🛒 Tienda | Tienda del Conocimiento |

### 5.4. Avisos

Cuando ocurre algo —se completa una misión, se gana una insignia, sube el rango— aparece un aviso temporal. No hay que hacer nada: desaparece solo.

---

## 6. Controles

### En computadora

| Tecla | Acción |
|---|---|
| **W A S D** o **flechas** | Mover al Eco-Ranger |
| **E** | Interactuar con lo que se tenga cerca: hablar con un NPC, entrar a un edificio, iniciar una misión |
| **1 – 5** | Abrir los paneles de la barra de acciones |
| **Esc** | Abrir y cerrar el menú de pausa |
| **Clic** | Todos los botones y paneles se manejan con el ratón |

> **Sobre la tecla E.** Si hay dos cosas cerca, el juego elige siempre **la más cercana**. Si no pasa nada al pulsarla, hay que acercarse más.

### En teléfono o tableta

Los controles táctiles aparecen solos al detectar la pantalla táctil:

- **Joystick (mitad izquierda):** se toca en cualquier punto y aparece ahí. Arrastrando se mueve el personaje.
- **Botón E (abajo a la derecha):** hace lo mismo que la tecla E.

**[CAPTURA 8]** — El juego en teléfono, con el joystick y el botón E visibles. (Se puede tomar desde el navegador de un teléfono, o con el modo de dispositivo móvil del navegador: **F12 → icono de teléfono**.)

---

## 7. Las actividades de aprendizaje

El juego tiene cinco tipos de actividad. Todas suman al puntaje del campus, pero cada una enseña de una forma distinta.

### 7.1. Diálogos con NPC

Los **NPC** (personajes no jugadores) son los coordinadores de cada área del campus: el Rector, el coordinador de energía, la encargada de residuos, y así. Tienen un nombre flotante sobre la cabeza.

Al acercarse y pulsar **E**, el NPC explica el módulo GreenMetric que le corresponde: qué mide, por qué importa, y qué se espera del estudiante. Es el contenido teórico del juego.

**[CAPTURA 9]** — Un diálogo con un NPC abierto.

### 7.2. Cuestionarios (quiz)

Después del diálogo, el NPC plantea un cuestionario de opción múltiple sobre lo que acaba de explicar.

Cómo funciona:

- Cada pregunta tiene **15 segundos** y una barra que muestra el tiempo restante. Si se agota, cuenta como fallo y el juego pasa a la siguiente.
- Al responder, el juego avisa de inmediato si fue correcto y, **si se falló, muestra cuál era la respuesta correcta**. Después de un segundo y medio continúa solo.
- Acertar varias seguidas activa una **racha**, que da experiencia extra.
- **Solo el primer intento del cuestionario completo suma al tramo *Quiz*** del panel GreenMetric. Se puede volver a hacerlo para repasar, pero esa repetición ya no cambia el puntaje de comprensión.
- Un cuestionario completo sin ningún fallo otorga la insignia **⭐ Puntaje Perfecto**.

> **Por qué solo cuenta el primer intento.** Si la repetición sumara, bastaría con reintentar hasta acertar por descarte y el tramo de comprensión dejaría de medir comprensión. Repetir sigue siendo útil para estudiar; lo que no hace es inflar el puntaje.

**[CAPTURA 10]** — Un cuestionario, con las opciones de respuesta y la barra de tiempo.
**[CAPTURA 11]** — La retroalimentación tras fallar una pregunta, mostrando la respuesta correcta.

### 7.3. Misiones de campo

Son las acciones concretas repartidas por el campus: plantar árboles, cambiar bombillos por LED, instalar contenedores de reciclaje, cerrar llaves que gotean, montar bicicleteros.

Se activan acercándose al punto señalado y pulsando **E**. Cada una explica qué se va a hacer y por qué mejora el indicador correspondiente.

Algunas misiones **necesitan una herramienta comprada en la tienda** (ver sección 11). Si falta, el juego lo dice y ofrece abrir la tienda con la herramienta ya señalada.

**[CAPTURA 12]** — Una misión de campo iniciándose.

### 7.4. Decisiones

En algunos puntos el juego no pide ejecutar una acción, sino **elegir entre alternativas**, cada una con un costo y un efecto distinto.

El caso más desarrollado es el **Nivel 5 (Plan de Movilidad)**: el estudiante recibe un presupuesto limitado y debe repartirlo entre seis medidas de transporte —permisos de estacionamiento, transporte compartido, servicio de transporte interno, día sin carros, renovación de flota— sabiendo que **no alcanza para todas**. Al final, el Consejo evalúa el plan completo.

Las respuestas no se revelan de antemano: el estudiante decide con la información que los NPC le dieron, y ve las consecuencias después.

**[CAPTURA 13]** — Un panel de decisión del Plan de Movilidad, con el presupuesto visible.
**[CAPTURA 14]** — El resultado del Consejo de Movilidad.

### 7.5. Crisis ambientales

Durante la exploración pueden aparecer **crisis al azar**: un apagón, una fuga de agua o una acumulación de basura.

- Hay **10 segundos** para elegir la respuesta correcta.
- Responder bien mejora el módulo afectado y otorga la insignia **🚨 Héroe de Crisis**.
- Responder mal o dejar pasar el tiempo no elimina progreso: solo se pierde la oportunidad.

Sirven para comprobar si el estudiante puede **aplicar** lo aprendido bajo presión, no solo recordarlo.

**[CAPTURA 15]** — Una crisis activa, con el contador de tiempo.

---

## 8. Los seis niveles

| Nivel | Módulo | Misiones | Qué se hace |
|---|---|---|---|
| **1** | 🌿 Infraestructura y Entorno | 6 | Plantar y recuperar áreas verdes en seis zonas del campus. |
| **2** | ⚡ Energía y Cambio Climático | 8 | Cambiar la iluminación de seis bloques a LED e instalar dos sistemas de paneles solares. |
| **3** | ♻ Manejo de Residuos | 6 | Instalar y atender seis puntos de donación y reciclaje. |
| **4** | 💧 Uso del Agua | 8 | Cerrar seis llaves con fugas e instalar dos sistemas de captación de agua de lluvia. |
| **5** | 🚲 Transporte Sostenible | 9 | Elaborar el Plan de Movilidad: seis decisiones presupuestarias, dos bicicleteros y la defensa ante el Consejo. |
| **6** | 📚 Educación e Investigación | 4 | Malla curricular verde, Comité Ambiental, Semana Verde e informe final. |

### Cómo se desbloquean

Se empieza en el **Nivel 1**. Cada nivel se abre al completar **todas** las misiones del anterior.

### El Nivel 6 cierra el ciclo

La última misión, el **informe final**, recopila las decisiones que el estudiante fue tomando a lo largo de todo el juego y las cita textualmente. El estudiante ve, en un solo documento, el recorrido completo que hizo y qué defendió en cada punto.

**[CAPTURA 16]** — El informe final del Nivel 6.

---

## 9. El puntaje GreenMetric del campus

El puntaje va de **0 a 100** y es el indicador central del juego: representa qué tan sostenible es el campus según las acciones del estudiante.

Se calcula a partir de los seis módulos, y dentro de cada módulo, de los cuatro componentes de la sección 5.2. La distribución **80 / 10 / 5 / 5** no es arbitraria: dice explícitamente que **la mayor parte del puntaje viene de actuar** (80 %), y el resto de comprender (10 %), decidir bien (5 %) y entender que las acciones se relacionan entre sí (5 %).

### Las sinergias

El tramo de **sinergias** es el que más enseña sobre el ranking real. Una acción de un módulo también mejora otro:

- Instalar paneles solares (Energía) reduce la huella de carbono, que también se mide en Infraestructura.
- Captar agua de lluvia (Agua) reduce el consumo energético de bombeo (Energía).
- Reducir el uso del automóvil (Transporte) mejora la calidad del aire del entorno (Infraestructura).

El estudiante descubre estas relaciones al ver subir una barra que no estaba tocando.

El botón **📊 Reporte** (tecla **2**) muestra el desglose completo: cuánto tiene cada módulo, en qué componente, y qué falta para completarlo.

**[CAPTURA 17]** — El Reporte GreenMetric abierto.

---

## 10. Recompensas: EcoCredits, rangos e insignias

### 10.1. EcoCredits (EC)

La moneda del juego. Se gastan en la Tienda del Conocimiento.

| Cómo se ganan | Cuánto |
|---|---|
| Bono al registrarse | 50 EC |
| Cada misión completada | Entre 12 y 20 EC, según el nivel |

No se pueden comprar con dinero real, no se pierden y no caducan.

### 10.2. Rangos

El rango depende de **cuántos niveles se han completado**, no del tiempo jugado:

| Niveles completados | Rango |
|---|---|
| 0 | Semilla |
| 1 | Brote |
| 2 | Árbol |
| 3 | Estratega |
| 4 – 5 | Investigador |
| **6** | **EcoLíder** |

El rango aparece en la ficha del jugador y junto al nombre en el ranking.

### 10.3. Insignias

Se otorgan automáticamente al cumplir la condición. **Las evalúa el servidor**, no el juego: no se pueden obtener por error ni perder por un fallo de conexión.

| Insignia | Se obtiene por |
|---|---|
| 🌿 Guardián Verde | Completar todas las misiones de Entorno e Infraestructura |
| ⚡ Ahorrista Solar | Completar todas las misiones de Energía y Cambio Climático |
| ♻ Eco Clasificador | Completar todas las misiones de Manejo de Residuos |
| 💧 Gota Vital | Completar todas las misiones de Uso del Agua |
| 🚲 Ciclista Campus | Completar todas las misiones de Transporte |
| 📚 EcoInvestigador | Completar todas las misiones de Educación e Investigación |
| ⭐ Puntaje Perfecto | Responder un cuestionario completo sin fallar ninguna pregunta |
| 🚨 Héroe de Crisis | Resolver correctamente una crisis ambiental |
| 🔥 Racha Ardiente | Jugar tres días seguidos |
| 🌱 Estela de Hojas | Canjearla en la tienda |
| 🏆 Embajador GreenMetric | Canjearla en la tienda |
| **🏆 EcoLíder URBE** | **Obtener todas las insignias que se ganan jugando** |

> **Una decisión de diseño que conviene explicar.** La insignia *EcoLíder URBE* **ignora las dos insignias que se compran**. Si contara las compradas, un estudiante podría conseguir el máximo reconocimiento del juego gastando EcoCredits en cosméticos en vez de completar el contenido educativo. Eso vaciaría de sentido la insignia.

**[CAPTURA 18]** — El panel de insignias, con algunas obtenidas y otras bloqueadas.

---

## 11. La Tienda del Conocimiento

Se abre con el botón **🛒 Tienda** o la tecla **5**.

**[CAPTURA 19]** — La tienda abierta, con el saldo de EcoCredits y los artículos.

### 11.1. Herramientas — necesarias para avanzar

Sin estas herramientas, ciertas misiones no se pueden ejecutar:

| Artículo | Precio | Hace falta para |
|---|---|---|
| ☀ Kit de instalación solar | 100 EC | Las misiones de paneles solares (Nivel 2) |
| 💧 Kit de captación pluvial | 60 EC | Las misiones de captación de lluvia (Nivel 4) |
| 🚲 Kit de bicicletero | 60 EC | Las misiones de bicicleteros (Nivel 5) |

### 11.2. Bonificaciones — opcionales

| Artículo | Precio | Efecto |
|---|---|---|
| 🌿 Termo reutilizable | 80 EC | +10 % de EcoCredits en cada misión |
| ⭐ Credencial de voluntario | 120 EC | +10 % de experiencia en cada misión |

### 11.3. Personalización — opcionales

| Artículo | Precio | Efecto |
|---|---|---|
| 🌱 Estela de hojas | 90 EC | El personaje deja un rastro de hojas al caminar |
| 🏆 Embajador GreenMetric | 150 EC | Un título junto al nombre en el ranking |

### 11.4. Reglas de la tienda

- **Un artículo se compra una sola vez.** No hay recompra ni consumibles.
- **El precio lo fija el servidor**, no el juego. No se puede alterar desde el navegador.
- **El saldo nunca queda negativo.** Si no alcanza, la compra se rechaza con un mensaje claro.
- **Hay una advertencia de protección:** si una compra opcional dejaría al estudiante sin EcoCredits suficientes para una herramienta obligatoria, el juego avisa y pide confirmación antes de cobrar. Así nadie queda atascado en un nivel por haber gastado en un cosmético.

---

## 12. El ranking

Se abre con el botón **🏆 Ranking** o la tecla **3**. Muestra los **50 mejores jugadores**, ordenados por experiencia:

| Puesto | Nombre | Rango | XP |
|---|---|---|---|

> **Sobre la privacidad.** El ranking muestra **únicamente** el nombre, el rango y la experiencia. **La cédula y el correo electrónico nunca aparecen**, ni en el ranking ni en ninguna otra pantalla visible para otros estudiantes. Es una restricción aplicada en el servidor, no una decisión de la interfaz.

**[CAPTURA 20]** — El ranking abierto.

---

## 13. Guardado del progreso

**No hay botón de guardar.** El juego guarda solo, en cada acción relevante: al completar una misión, responder un cuestionario, comprar en la tienda o tomar una decisión.

Lo que se conserva entre sesiones:

- Todas las misiones completadas y en qué nivel
- El puntaje GreenMetric de cada módulo
- Los EcoCredits y lo comprado
- Las insignias obtenidas
- **La posición del personaje en el campus** — al volver a entrar, el Eco-Ranger aparece donde se quedó

El progreso está ligado a la **cuenta**, no a la computadora: se puede empezar en el laboratorio y continuar en el teléfono, con el mismo correo. Misiones, puntaje, EcoCredits, compras e insignias viajan con la cuenta.

> **Una excepción.** La **posición del personaje** se guarda en el propio navegador, no en el servidor. Al cambiar de dispositivo —o al borrar los datos de navegación— el progreso sigue intacto, pero el Eco-Ranger reaparece en el punto de partida del campus en lugar de donde se quedó.

> **Si el juego se cierra de golpe** —se cae internet, se apaga el equipo, se cierra la pestaña sin querer— **no se pierde nada** más allá de la acción que estaba justo en curso.

---

## 14. Solución de problemas

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| La pantalla de carga no avanza | Conexión lenta o intermitente | Esperar. Si pasan varios minutos, recargar con **F5**. |
| "Correo no permitido" al registrarse | El dominio del correo no está en la lista autorizada | Usar un correo de un dominio permitido; el mensaje indica cuáles. |
| Olvidé mi contraseña | — | Avisarle al docente, que la cambia en el momento. La pantalla de recuperación por correo todavía no está en servicio. |
| Pulso **E** y no pasa nada | El personaje está demasiado lejos | Acercarse más al NPC o al punto de la misión. |
| Una misión dice que falta una herramienta | No se ha comprado el kit correspondiente | Abrir la tienda (tecla **5**) y comprarlo. El juego señala cuál. |
| No alcanzan los EcoCredits | Se gastaron en artículos opcionales | Completar más misiones de los niveles ya abiertos: cada una da EcoCredits. |
| El juego se ve cortado o desalineado | Ventana muy pequeña, o zoom del navegador alterado | Poner el zoom en 100 % (**Ctrl + 0**) y maximizar la ventana. |
| No aparece el joystick en el teléfono | El navegador no reportó la pantalla táctil | Recargar la página. |
| Actualizaron el juego pero se ve igual | El navegador guardó la versión anterior | Recargar forzando: **Ctrl + Shift + R**. |
| El progreso no aparece | Se entró con otra cuenta | Cerrar sesión y entrar con el correo con el que se registró. |

---

## 15. Para el docente o supervisor

Esta sección no es necesaria para jugar.

### 15.1. Qué registra el sistema

Cada acción del estudiante queda guardada en el servidor, con fecha y hora:

| Se registra | Para qué sirve |
|---|---|
| Misiones iniciadas y completadas | Ver el avance y cuánto tarda cada actividad |
| Respuestas de cuestionario, con acierto o fallo | Identificar qué contenidos cuestan más |
| Decisiones tomadas | Ver el criterio con que el estudiante resuelve |
| Crisis resueltas | Ver si aplica lo aprendido bajo presión |
| Puntaje GreenMetric por módulo | Medir el resultado de aprendizaje |

Con estos datos se puede responder, por ejemplo, **qué pregunta falla la mayoría** —lo que señala un contenido mal explicado, en el juego o en el aula.

### 15.2. Cómo consultarlos

Las consultas están preparadas en la carpeta `sql/` del repositorio del proyecto y se ejecutan desde el panel de administración de la base de datos. Requieren credenciales de administrador, que **no** se entregan a los estudiantes.

### 15.3. Sobre la privacidad de los estudiantes

- La cédula y el correo se guardan, pero **nunca se muestran a otros usuarios**.
- El ranking expone solo nombre, rango y experiencia.
- Las contraseñas no se guardan en texto legible: el sistema de autenticación las guarda cifradas y ni siquiera un administrador puede leerlas.

---

## 16. Glosario

| Término | Significado |
|---|---|
| **UI GreenMetric** | Ranking mundial que evalúa la sostenibilidad de las universidades, publicado por la Universitas Indonesia. Se organiza en seis módulos. |
| **Eco-Ranger** | El personaje que controla el estudiante. |
| **NPC** | *Non-Player Character*. Personaje controlado por el juego: los coordinadores de cada área del campus. |
| **EcoCredits (EC)** | Moneda del juego, para comprar en la Tienda del Conocimiento. |
| **XP** | Experiencia. Determina el puesto en el ranking. |
| **Rango** | Nivel de reconocimiento del estudiante, de *Semilla* a *EcoLíder*. Depende de cuántos niveles completó. |
| **Insignia** | Reconocimiento por un logro concreto. Las otorga el servidor automáticamente. |
| **Sinergia** | Cuando una acción de un módulo también mejora otro. |
| **HUD** | *Heads-Up Display*. La información permanente en pantalla: ficha, panel GreenMetric y barra de acciones. |
| **Misión de campo** | Acción concreta que se ejecuta en un punto del campus. |
| **Crisis** | Evento aleatorio con 10 segundos para responder. |

---

*Manual de usuarios de **URBE Rangers: Eco-Quest**, entorno virtual de aprendizaje gamificado desarrollado como trabajo especial de grado en la Universidad Dr. Rafael Belloso Chacín, Maracaibo, 2026.*
