# GreenMetric URBE — URBE Rangers: Eco-Quest

Juego educativo 2D (Godot 4.7) donde el jugador recorre un campus universitario
y resuelve misiones de campo mapeadas 1:1 a los 6 módulos del ranking
[UI GreenMetric World University Ranking](https://greenmetric.ui.ac.id/):
Infraestructura, Energía, Residuos, Agua, Transporte, y Educación e Investigación.

🎮 **Jugar en el navegador:** https://ereyes05.github.io/green-metric-urbe/juego/ — no hace falta instalar nada.

📄 **[docs/ESTADO_PROYECTO.md](docs/ESTADO_PROYECTO.md)** — contexto completo del proyecto para el equipo: qué hay hecho, decisiones de diseño, pendientes conocidos. Se mantiene actualizado en cada cambio importante — léelo antes de empezar a trabajar acá.

## Documentos, por si buscás algo puntual

| Documento | Para qué |
|---|---|
| [ESTADO_PROYECTO.md](docs/ESTADO_PROYECTO.md) | El contexto completo. Empezar por acá. |
| [manual_usuarios.md](docs/manual_usuarios.md) | **Borrador** del manual de usuarios (objetivo específico 6). Le faltan las 20 capturas. |
| [revision_capitulos.md](docs/revision_capitulos.md) | Qué le falta a la tesis, capítulo por capítulo. **Lo más urgente está acá.** |
| [auditoria_capitulo4.md](docs/auditoria_capitulo4.md) | Las 18 tablas del Cap. 4 contra lo que el juego hace de verdad. |
| [revision_capitulo3.md](docs/revision_capitulo3.md) | Correcciones del marco metodológico. |
| [redaccion_cap4_pendiente.md](docs/redaccion_cap4_pendiente.md) | Texto propuesto para el Cap. 4. |
| [guia_prueba_usabilidad.md](docs/guia_prueba_usabilidad.md) | Cómo correr la sesión con los 4 estudiantes piloto. |
| [supabase_correos.md](docs/supabase_correos.md) | Por qué el registro no manda correo y qué haría falta para que mande. |
| [matriz_cobertura_greenmetric.md](docs/matriz_cobertura_greenmetric.md) | Qué indicador de GreenMetric cubre cada misión. |

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

Escena principal: `scenes/login/scene_login.tscn` (login/registro) → `scenes/mapa/scene_mapa_mundo.tscn`.

## Arquitectura

- **`autoload/`** — singletons globales (cargados siempre, en este orden en `project.godot`):
  - `SupabaseManager.gd` — todas las peticiones HTTP a Supabase (auth, progreso, telemetría, leaderboard).
  - `EconomiaManager.gd` — EcoCredits, inventario de la tienda e insignias. Las insignias las decide el **servidor** (`sql/insignias_1_migracion.sql`); acá solo se reflejan. El sistema de energía/vidas se eliminó el 2026-09-20: estaba a medio hacer y no lo pedía ningún capítulo.
  - `AudioManager.gd`, `WindowManager.gd` — utilidades.
  - `NivelManager.gd` — **fuente de verdad del progreso**: qué misiones de campo (de las 41 totales, repartidas en 6 niveles) están completas. El guardado local es **por cuenta** (`user://nivel_progreso_<uid>.json`) y el servidor lo repuebla al entrar, así que el progreso viaja entre dispositivos. `MISIONES_NIVEL` es espejo de `public.catalogo_misiones`: si cambia uno, cambiar el otro.
- **`scenes/mapa/SceneMapaMundo.gd`** — el archivo más grande del proyecto (~2.200 líneas): mapa, HUD, spawns de las 41 misiones, UI de resultados y leaderboard. Punto de entrada para entender cómo se conecta todo.
- **`scenes/misiones/`** — una misión = típicamente 2 scripts: `punto_*.gd` (Area2D interactivo en el mapa, detecta al jugador, dibuja su propio ícono) + `mision_*.gd` (CanvasLayer con la UI/lógica de la interacción). El patrón se repite en los 6 niveles — copiar el par más parecido es más rápido que empezar de cero.
- **`scenes/edificios/`, `scenes/ui/`, `scenes/login/`, `scenes/minijuego/`** — interiores de edificios, pantallas de UI reutilizables (quiz, resultados, leaderboard, simulador de decisiones), login/registro, minijuego de residuos.
- **`sql/`** — migraciones de Supabase para ejecutar a mano en el SQL Editor del dashboard (no hay CLI de Supabase configurada en el proyecto). Hoy hay 14 archivos: puntaje, tienda, insignias, ranking, eventos, Nivel 5 y consultas de métricas. Siguen **sin versionar** `progreso_estudiante`, `modulos_greenmetric`, la tabla de estudiantes y el trigger `handle_new_user` (el que valida el dominio del correo al registrarse) — si hay que recrearlas, hay que reconstruir el schema desde el dashboard o desde `SupabaseManager.gd` (los payloads que envía indican las columnas mínimas esperadas).

## Backend (Supabase)

- Proyecto: `ikohikbpvtbvsgyumvbr` (ver `SUPABASE_URL` en `SupabaseManager.gd`).
- La anon key en `SupabaseManager.gd` es pública por diseño (protegida por RLS, no por estar oculta) — no es un secreto que rotar.
- El token de administración del proyecto (para MCP/CLI) vive en `.mcp.json`, que está en `.gitignore` — nunca commitear ese archivo.
- **Nota de seguridad conocida:** `SupabaseManager.guardar_progreso()` envía XP/puntaje calculados en el cliente. RLS restringe *a nombre de quién* se escribe, no *qué valores* se pueden escribir — un cliente modificado podría inflar su propio progreso. No es un problema si esto es solo una demo; sí importa si el leaderboard o los datos de `progreso_estudiante` se usan para evaluar a estudiantes.

## Estado / limitaciones conocidas

- **22 suites de prueba** en `tests/`, sin CI. Se corren a mano y una suite verde es código de salida 0:

  ```
  godot --headless --path . res://tests/test_login.tscn
  ```

  Son pruebas sin red: no tocan Supabase ni dejan datos. Lo que **no** cubren es cómo se ve la pantalla ni si una misión quedó dentro de una pared — eso sigue siendo jugar y mirar.
- `SceneMapaMundo.gd` concentra demasiado — si el proyecto sigue creciendo, separar por nivel antes de que se vuelva inmanejable.
