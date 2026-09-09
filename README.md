# GreenMetric URBE — URBE Rangers: Eco-Quest

Juego educativo 2D (Godot 4.7) donde el jugador recorre un campus universitario
y resuelve misiones de campo mapeadas 1:1 a los 6 módulos del ranking
[UI GreenMetric World University Ranking](https://greenmetric.ui.ac.id/):
Infraestructura, Energía, Residuos, Agua, Transporte, y Educación e Investigación.

📄 **[docs/ESTADO_PROYECTO.md](docs/ESTADO_PROYECTO.md)** — contexto completo del proyecto para el equipo: qué hay hecho, decisiones de diseño, pendientes conocidos. Se mantiene actualizado en cada cambio importante — léelo antes de empezar a trabajar acá.

## Requisitos

- **Godot 4.7** (stable, GL Compatibility). El proyecto usa el sistema de UID de
  recursos de Godot 4 — los archivos `.gd.uid` están versionados junto a cada
  script; si faltan, Godot los regenera solo al abrir el editor (no hace falta
  tocarlos a mano, pero si añadís un script nuevo, commiteá su `.uid`).
- Conexión a internet para login/registro/progreso (usa Supabase, ver abajo).

## Correr el proyecto

Abrir la carpeta del repo con el editor de Godot 4.7, o desde línea de comandos:

```
godot --path . -e     # abre el editor
godot --path .         # corre el juego directo
```

Escena principal: `scenes/login/SceneLogin.tscn` (login/registro) → `scenes/mapa/scene_mapa_mundo.tscn`.

## Arquitectura

- **`autoload/`** — singletons globales (cargados siempre, en este orden en `project.godot`):
  - `SupabaseManager.gd` — todas las peticiones HTTP a Supabase (auth, progreso, telemetría, leaderboard).
  - `EconomiaManager.gd` — EcoCredits, energía/vidas, insignias, ImpactRating por módulo.
  - `AudioManager.gd`, `WindowManager.gd` — utilidades.
  - `NivelManager.gd` — **fuente de verdad del progreso**: qué misiones de campo (de las 40 totales, repartidas en 6 niveles) están completas, guardado local en `user://nivel_progreso.json` con backup automático.
- **`scenes/mapa/SceneMapaMundo.gd`** — el archivo más grande del proyecto (~2800 líneas): mapa, HUD, spawns de las 40 misiones, UI de resultados y leaderboard. Punto de entrada para entender cómo se conecta todo.
- **`scenes/misiones/`** — una misión = típicamente 2 scripts: `punto_*.gd` (Area2D interactivo en el mapa, detecta al jugador, dibuja su propio ícono) + `mision_*.gd` (CanvasLayer con la UI/lógica de la interacción). El patrón se repite en los 6 niveles — copiar el par más parecido es más rápido que empezar de cero.
- **`scenes/edificios/`, `scenes/ui/`, `scenes/login/`, `scenes/minijuego/`** — interiores de edificios, pantallas de UI reutilizables (quiz, resultados, leaderboard, simulador de decisiones), login/registro, minijuego de residuos.
- **`sql/`** — migraciones de Supabase para ejecutar a mano en el SQL Editor del dashboard (no hay CLI de Supabase configurada en el proyecto). `eventos_aprendizaje.sql` es la única versionada hoy; `progreso_estudiante` y `modulos_greenmetric` existen en Supabase pero **no tienen migración en el repo** — si hay que recrearlas, hay que reconstruir el schema desde el dashboard o desde `SupabaseManager.gd` (los payloads que envía indican las columnas mínimas esperadas).

## Backend (Supabase)

- Proyecto: `ikohikbpvtbvsgyumvbr` (ver `SUPABASE_URL` en `SupabaseManager.gd`).
- La anon key en `SupabaseManager.gd` es pública por diseño (protegida por RLS, no por estar oculta) — no es un secreto que rotar.
- El token de administración del proyecto (para MCP/CLI) vive en `.mcp.json`, que está en `.gitignore` — nunca commitear ese archivo.
- **Nota de seguridad conocida:** `SupabaseManager.guardar_progreso()` envía XP/puntaje calculados en el cliente. RLS restringe *a nombre de quién* se escribe, no *qué valores* se pueden escribir — un cliente modificado podría inflar su propio progreso. No es un problema si esto es solo una demo; sí importa si el leaderboard o los datos de `progreso_estudiante` se usan para evaluar a estudiantes.

## Estado / limitaciones conocidas

- No hay tests automatizados ni CI — todo QA es manual, jugando, o scripts puntuales fuera del repo (ver historial de commits para ejemplos de verificaciones geométricas de posiciones de misión contra colisiones de edificios).
- `SceneMapaMundo.gd` concentra demasiado — si el proyecto sigue creciendo, separar por nivel antes de que se vuelva inmanejable.
