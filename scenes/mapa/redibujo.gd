# Frecuencia de redibujo de los íconos animados del mapa.
#
# Rendimiento web (medido 2026-11-06, Chrome + Intel UHD 620): los íconos de
# misión (papeleras, puntos de energía, cisternas, grifos, eventos…) llamaban
# queue_redraw() en CADA cuadro, y rehacer su _draw() en GDScript costaba
# ~19 ms de un cuadro de 47 ms (21 FPS). Sus animaciones son pulsos de brillo
# y movimientos lentos: redibujarlos a ~12 Hz no se distingue, y cada uno
# arranca en una fase al azar para que no coincidan todos en el mismo cuadro.
#
# Uso, en el _process del visual:
#     _redibujo -= delta
#     if _redibujo <= 0.0:
#         _redibujo = Redibujo.CADA
#         queue_redraw()
# con `var _redibujo : float = randf() * Redibujo.CADA`.
extends RefCounted

## Segundos entre redibujos. 0 = en cada cuadro (como antes; para medir).
static var CADA : float = 1.0 / 12.0
