# ============================================================
# colision_tilemap.gd - URBE Rangers: Eco-Quest
# Colisiones alineadas al layout de cuadrícula de mapa_campus.gd
# Tile 16x16 px. Formato: [cx, cy, ancho, alto] en píxeles.
# ============================================================

extends TileMapLayer

const TS : int = 16

# Posiciones exactas extraídas de los Rect2 en mapa_campus.gd
# [cx, cy, w, h]  (centro = pos + size/2)
# Layout real URBE — basado en foto aérea del campus
const EDIFICIOS : Array = [
	# Lago norte y=0..80
	[704,  40, 1408,  80],

	# Cafetín M3  x=280..480, y=120..280
	[380, 200,  200, 160],

	# Bloque E M2  x=700..1080, y=120..420
	[890, 270,  380, 300],

	# Estudios a Distancia M1  x=1120..1408, y=120..660
	[1264, 390,  288, 540],

	# Bloque D M2  x=280..480, y=320..480
	[380, 400,  200, 160],

	# Bloque C M2  x=280..460, y=520..640
	[370, 580,  180, 120],

	# Bloque B M2  x=520..700, y=520..640
	[610, 580,  180, 120],

	# Rectorado M6  x=740..1060, y=480..660
	[900, 570,  320, 180],

	# Fotocopiado M1  x=0..180, y=580..700
	[ 90, 640,  180, 120],

	# Bloque A M2  x=280..700, y=680..740
	[490, 710,  420,  60],
]

var _source_id : int = 0

func _ready() -> void:
	_crear_tileset()
	_pintar_edificios()
	visible = false
	print("OK ColisionTileMap: %d edificios" % EDIFICIOS.size())


func _crear_tileset() -> void:
	var img := Image.create(TS, TS, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.2, 0.2, 0.7))
	var tex := ImageTexture.create_from_image(img)

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TS, TS)
	source.create_tile(Vector2i(0, 0))

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)
	_source_id = ts.add_source(source)

	var h  : float    = TS * 0.5
	var td : TileData = source.get_tile_data(Vector2i(0, 0), 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h),
		Vector2(h,  h),  Vector2(-h, h)
	]))

	tile_set = ts


func _pintar_edificios() -> void:
	for e in EDIFICIOS:
		var cx  : float = float(e[0])
		var cy  : float = float(e[1])
		var aw  : float = float(e[2])
		var ah  : float = float(e[3])
		var tx0 : int   = int(floor((cx - aw * 0.5) / TS))
		var ty0 : int   = int(floor((cy - ah * 0.5) / TS))
		var tx1 : int   = int(ceil( (cx + aw * 0.5) / TS))
		var ty1 : int   = int(ceil( (cy + ah * 0.5) / TS))
		for gx in range(tx0, tx1):
			for gy in range(ty0, ty1):
				set_cell(Vector2i(gx, gy), _source_id, Vector2i(0, 0))
