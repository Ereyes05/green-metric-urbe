# HUD plano — especificación 2b (aprobada 2026-09-15)

Propuesta de Claude Design elegida por el usuario (mockup "HUD final — estilo
plano (1a)", captura 2a). Se descartó la variante pixel art (3a) por estética.
**Implementado 2026-09-16** (plan
`docs/superpowers/plans/2026-09-16-hud-plano-rangos-ranking.md`); falta
prueba en el juego con cuenta real y re-export web.

## Decisiones tomadas junto con esta especificación

- **Estilo:** plano (resuelve la brecha 4 de la sección 9 de ESTADO_PROYECTO:
  Tabla 2 del Cap. 4). Implementar con todos los colores/fuentes/radios en un
  único archivo de tema (`scenes/ui/hud_tema.gd`) para poder cambiar de estilo
  sin rehacer el HUD.
- **Íconos:** emojis (la web usa la fuente NotoColorEmoji-subset; agregar los
  que falten). El atlas de íconos PNG es opcional.
- **Rangos:** uno por nivel completado — Semilla (inicio), Brote (Nivel 1),
  Árbol (Nivel 2), Estratega (Nivel 3), Investigador (Nivel 4), EcoLíder
  (los 6 niveles). La ficha muestra "XP hacia <rango siguiente>" (el mockup
  decía "Bosque", que no existe). Antes eran por XP y con ~2.800 XP totales
  en el juego nadie pasaba de Árbol/Estratega.
- **Nivel de misiones y rango separados:** "Nivel 6/6 · Educación" vs "Rango".
- **Ranking:** nombre + inicial (ej. "Edward R."), XP y título de la tienda,
  vía función pública en Supabase que lee `estudiantes` sin exponer cédula ni
  correo; "(Tú)" se marca comparando por user_id. Causa del ranking vacío:
  `cargar_ranking` lee `progreso_estudiante` (tabla vieja, 6 filas) con la
  clave anónima y la RLS solo deja ver filas propias.
- **Puntaje campus:** el número real de `PuntajeManager.total` (el mockup
  mostraba 67; con los datos reales da 66).

## Especificación 2b (texto de Claude Design)

### Canvas · tipografía · tokens
- **Resolución:** 1280 × 720 · stretch mode canvas_items · aspect keep
- **Safe area:** 16 px en los 4 bordes · corredor central libre x 300 → 996 (712 px)
- **Fuentes:** cuerpo Rubik 400/600/700 · títulos Press Start 2P
- **Escala de texto:** 8 / 9 / 10 / 11 / 12 / 13 / 16 px (nunca < 8)
- **Fondo panel:** #101C26 al 86 % → StyleBoxFlat bg_color rgba(16,28,38,0.86)
- **Track de barra:** #000000 al 50 %
- **Texto:** primario #EAF2EE · secundario #C9D8D3 · terciario #9FB3AE · apagado #7E938E
- **Acentos:** #62D06A verde · #3FBEDC cian · #E8BE55 dorado · #E5893E naranja · #9B77DF violeta · #4FD1B0 teal · #E8556B vidas
- **Radios:** panel 12 · caja interna 8 · botón 10 · chip 6 · barra = altura / 2
- **Bordes:** 2 px sólidos en paneles y botones · 1 px en cajas internas

### 1 · Ficha del jugador (arriba izq.)
- **Panel:** pos 16,16 · 268 × 235 · radius 12 · border 2 #62D06A · padding 10/12/12 · gap 8 (alto = suma de filas; en Godot dejar el VBox en fit_content)
- **Fila 1 nombre:** h 17 · emoji 14 · «Eco-Ranger» Press Start 2P 11 px #EAF2EE · 3 corazones 12 px #E8556B (gap 2, vacío #3A4550)
- **Fila 2 misiones:** caja h 34 · radius 8 · bg rgba(79,209,176,0.12) · border 1 rgba(79,209,176,0.45) · padding 5/8 · gap 8
  - etiqueta «NIVEL DE MISIONES» Rubik 9 px #7E938E · letter-spacing 0.8
  - valor «Nivel 6/6 · Educación» Rubik 600 12 px #EAF2EE
  - pasos: 6 barritas 4 × 12 · radius 1 · gap 2 · hechas #4FD1B0 / pendientes #24323C
- **Fila 3 rango:** h 17 · emoji 12 · «RANGO» 9 px #7E938E + «Árbol» Rubik 600 12 px #E8BE55 · derecha «💰 319 EC» Rubik 600 13 px #E8BE55
- **Barra XP:** h 10 · radius 5 · fill #3FBEDC · progreso 45 % · gap 4 sobre la fila de texto
- **Texto XP:** izq. «XP hacia <rango siguiente>» / der. «1578 / 3500» Rubik 10 px #9FB3AE tabular
- **Separador:** 1 px rgba(255,255,255,0.10)
- **Índices:** DENTRO del panel · título «ÍNDICES DEL CAMPUS» 10 px #7E938E · 3 filas h 14 gap 6
  - fila: icono 14 px · label 64 px Rubik 11 px #C9D8D3 · barra flex h 6 r 3 · % 32 px der. Rubik 600 11 px #EAF2EE
  - colores: Verde #62D06A · Agua #3FBEDC · Educación #4FD1B0

### 2 · Panel GreenMetric (arriba der.)
- **Panel:** pos 996,16 · 268 × 343 · radius 12 · border 2 #3FBEDC · padding 10/12/12 · gap 8
- **Título:** «GreenMetric» Press Start 2P 10 px #3FBEDC · der. «0–100» Rubik 10 px #7E938E
- **Puntaje campus:** caja h 46 · radius 8 · bg rgba(63,190,220,0.12) · border 1 rgba(63,190,220,0.45) · padding 7/9 · gap 10
  - número Press Start 2P 16 px #EAF2EE · barra h 8 r 4 fill #3FBEDC
- **Fila categoría:** h 34 · padding vertical 3 · label 17 + barra 7
  - label: icono 14 px · nombre Rubik 12 px #EAF2EE · % Rubik 600 11 px #C9D8D3
- **Barra 80/10/5/5:** h 7 · margin-left 20 · 4 tramos con stretch_ratio 80/10/5/5 · separación 2 · radius 3 solo en extremos
  - opacidad 1.00 misiones / 0.78 quiz / 0.58 decisiones / 0.40 sinergias, sobre el color de la categoría
- **Colores categoría:** Entorno #62D06A · Energía #E8BE55 · Residuos #E5893E · Agua #3FBEDC · Transporte #9B77DF · Educación #4FD1B0
- **Popover:** 186 px ancho · radius 10 · border 2 #3FBEDC · bg rgba(10,18,25,0.97) · padding 9/10 · a la izquierda del panel, gap 10, alineado top −6
  - contenido: título 11 px 600 + 4 filas (chip 8 × 8 r 2, label 10 px #C9D8D3, valor 10 px #EAF2EE) + línea «Falta:» 10 px #E8BE55
- **Leyenda:** borde sup. 1 px rgba(255,255,255,0.10) · padding-top 7 · chips 7 × 7 r 2 gris #8FA0A8 con la misma escala de opacidad · texto 9 px #9FB3AE

### 3 · Acciones · 4 · Banner · 5 · Aviso
- **Grupo botones:** pos 16, bottom 16 (y 645) · 5 botones · gap 6 · grupo 304 × 59
- **Botón:** 56 × 59 · radius 10 · border 2 del color propio · padding 6/2/5 · gap 3
  - contenido: emoji 19 px · label Rubik 600 9 px #EAF2EE · tecla Rubik 8 px #9FB3AE
  - colores: 🌡 #E5893E · 📊 #3FBEDC · 🏆 #E8BE55 · 🔬 #9B77DF · 🛒 #62D06A
  - estados: hover bg = color al 18 % · focus outline 2 px #EAF2EE · pressed escala 0.96 (0,08 s)
- **Banner zona:** 420 × 51 · x 430 · bottom 16 (bottom = y 653) · radius 12 · border 2 = color de la categoría de la zona
  - contenido: emoji 20 px · título Press Start 2P 11 px #EAF2EE · niveles Rubik 11 px en color · hint «E · interactuar» 10 px #7E938E
  - animación: entra 0,18 s (fade + 12 px arriba) · visible 3 s · sale 0,25 s
- **Aviso central:** auto × 40 · centrado x · top 20 · radius 10 · border 2 #E8BE55 (bloqueo #E8556B) · padding 8/14 · gap 8
  - texto Rubik 600 13 px #EAF2EE · deltas 13 px 600 en color de la categoría
  - animación: entra 0,15 s desde y+4 · visible 2 s · sale 0,2 s · cola máx. 2

### Implementación en Godot 4.7
- **Texturas PNG:** ninguna. Todo con StyleBoxFlat (bg_color + border_width_* + corner_radius_* + content_margin_*).
- **Único asset opcional:** atlas de íconos PNG 32 × 32 (@1x) / 64 × 64 (@2x), 14 íconos (6 categorías + 3 índices + 5 herramientas), archivo 448 × 32.
- **Fuentes:** Rubik-Regular/Medium/Bold.ttf + PressStart2P-Regular.ttf embebidas; antialias activado en Rubik, desactivado en Press Start 2P.
- **Jerarquía:** HUD (CanvasLayer 1) → MarginContainer(16) → cada panel como PanelContainer + VBoxContainer; Toast en CanvasLayer 2.
- **Anclajes:** ficha top-left · GreenMetric top-right · acciones bottom-left · banner y aviso center (anchors_preset 7 / 5).
- **Barras:** ProgressBar con StyleBoxFlat fg/bg, o Panel + ColorRect con anchor_right animado (tween 0,3 s ease_out) para XP e índices.
- **Barra segmentada:** HBoxContainer (separation 2) con 4 Panel de stretch_ratio 80/10/5/5, cada uno con un ColorRect hijo; corner_radius solo en el primero y el último.
- **Popover:** PanelContainer oculto, se muestra en mouse_entered / focus_entered de la fila; top_level = true.
- **Texto tabular:** Label con fuente Rubik y OpenType feature tnum, o LabelSettings con fuente monoespaciada para los números.

## Desvíos respecto de la spec

Rulings de diseño tomados al escribir el plan y durante la implementación
(no estaban en la especificación 2b original):

- **Barra "hacia el siguiente rango":** los rangos ya no dependen del XP, así
  que la barra muestra el avance de misiones del/los nivel(es) que faltan
  para el siguiente rango (con 4 o 5 niveles completos, EcoLíder pide el 5 y
  el 6). Texto izq. «Hacia Estratega», der. «1578 XP». Con EcoLíder: «Rango
  máximo» y barra llena.
- **Nombre + inicial:** primer nombre + inicial del primer apellido.
  `estudiantes.nombre` guarda 3–4 palabras: con 4+ palabras el apellido es la
  3.ª, con 2–3 es la 2.ª. Vacío o con "@" → "Eco-Ranger".
- **Banner de zona:** queda visible mientras el jugador está en la zona (la
  pista «E · interactuar» debe verse); se anima al entrar (0,18 s) y al salir
  (0,25 s). La notificación central al entrar a una zona se elimina
  (duplicaba el banner).
- **Capas:** el HUD sigue en el CanvasLayer existente (layer 5) con el aviso
  en el mismo canvas; no se crean CanvasLayer 1/2.
- **Emoji de rango:** «⭐» (ya está en el recorte de NotoColorEmoji).
- **Celebración:** la de "¡NIVEL SUBIDO!" por XP se elimina; al subir de
  rango se muestra un aviso central «⭐ Nuevo rango: <nombre>».
- **Aviso "Faltan N EC":** se muestra como bloqueo (borde rojo #E8556B), no
  con el borde dorado por defecto — es un aviso que impide una acción, no una
  notificación informativa.
- **Colores de `CATEGORIAS`:** referencian los tokens de `hud_tema.gd` en vez
  de repetir valores hex propios, para que un cambio de tema no desalinee
  los colores de categoría del resto del HUD.
