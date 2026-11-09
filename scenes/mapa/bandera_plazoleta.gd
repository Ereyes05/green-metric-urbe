extends Sprite2D
## Bandera de la Plazoleta Central.
## El jugador usa z_index = 2. Si camina por DETRÁS del asta (más arriba en
## pantalla que la base), la bandera se dibuja encima de él; si pasa por
## DELANTE, queda debajo. Así no lo tapa siempre ni él la pisa.

const Z_DELANTE := 3   # por encima del jugador
const Z_DETRAS  := 1   # por debajo del jugador, encima del mapa

## Corrige la altura de la base si la imagen tiene espacio vacío abajo.
## Negativo = sube el punto de corte; positivo = lo baja.
@export var ajuste_base: float = 0.0

var _pies_jugador: Node2D


func _ready() -> void:
	# Los "pies" del jugador son su CollisionShape2D (está 11 px bajo su origen).
	_pies_jugador = get_parent().get_node_or_null("Jugador/CollisionShape2D")


func _process(_delta: float) -> void:
	if _pies_jugador == null or texture == null:
		return
	var alto := texture.get_height() * scale.y
	var base_y := global_position.y + (alto * 0.5 if centered else alto) + ajuste_base
	z_index = Z_DELANTE if _pies_jugador.global_position.y < base_y else Z_DETRAS
