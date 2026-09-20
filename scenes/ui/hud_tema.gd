# ============================================================
# hud_tema.gd — único lugar con colores, fuentes y radios del HUD
# (especificación 2b, docs/diseno/hud_plano_2b.md). Cambiar de estilo
# = cambiar este archivo, no los paneles.
# ============================================================
extends RefCounted

const RUTA_RUBIK := "res://assets/fonts/Rubik-VariableFont_wght.ttf"
const RUTA_PIXEL := "res://assets/fonts/PressStart2P-Regular.ttf"
const RUTA_EMOJI := "res://assets/fonts/NotoColorEmoji-subset.ttf"

const PANEL_BG       := Color(16 / 255.0, 28 / 255.0, 38 / 255.0, 0.86)  # #101C26 86 %
const TRACK          := Color(0.0, 0.0, 0.0, 0.5)
const TEXTO          := Color("#EAF2EE")
const TEXTO_2        := Color("#C9D8D3")
const TEXTO_3        := Color("#9FB3AE")
const APAGADO        := Color("#7E938E")
const VERDE          := Color("#62D06A")
const CIAN           := Color("#3FBEDC")
const DORADO         := Color("#E8BE55")
const NARANJA        := Color("#E5893E")
const VIOLETA        := Color("#9B77DF")
const TEAL           := Color("#4FD1B0")
# Rojo de alerta. Se llamaba VIDAS por los corazones del HUD, que se
# quitaron el 2026-09-20 (ver docs/auditoria_capitulo4.md, Tabla 10).
const ALERTA         := Color("#E8556B")
const VACIO          := Color("#3A4550")
const PASO_PENDIENTE := Color("#24323C")
const LEYENDA        := Color("#8FA0A8")
const POPOVER_BG     := Color(10 / 255.0, 18 / 255.0, 25 / 255.0, 0.97)  # rgba(10,18,25,.97)
const SEPARADOR      := Color(1.0, 1.0, 1.0, 0.10)

const CATEGORIAS : Array = [
	{},
	{"icono": "🌿", "nombre": "Entorno",    "color": VERDE},
	{"icono": "⚡", "nombre": "Energía",    "color": DORADO},
	{"icono": "♻", "nombre": "Residuos",   "color": NARANJA},
	{"icono": "💧", "nombre": "Agua",       "color": CIAN},
	{"icono": "🚲", "nombre": "Transporte", "color": VIOLETA},
	{"icono": "📚", "nombre": "Educación",  "color": TEAL},
]

const EMOJIS_HUD : Array[String] = [
	"🌿", "⚡", "♻", "💧", "🚲", "📚", "⭐", "💰", "🌡", "📊", "🏆", "🔬", "🛒", "✨", "🔒", "♥",
]

static var _rubik_cache : Dictionary = {}
static var _pixel : Font = null


static func caja(bg: Color, borde: Color, ancho_borde: int, radio: int, pad_h: int = 0, pad_v: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = borde
	s.set_border_width_all(ancho_borde)
	s.set_corner_radius_all(radio)
	s.content_margin_left = pad_h
	s.content_margin_right = pad_h
	s.content_margin_top = pad_v
	s.content_margin_bottom = pad_v
	s.anti_aliasing = true
	return s


static func panel(color_borde: Color) -> StyleBoxFlat:
	var s := caja(PANEL_BG, color_borde, 2, 12, 12, 12)
	s.content_margin_top = 10
	return s


static func _emoji() -> Font:
	return load(RUTA_EMOJI) as Font if ResourceLoader.exists(RUTA_EMOJI) else null


static func rubik(peso: int = 400, tabular: bool = false) -> Font:
	var clave := "%d_%s" % [peso, tabular]
	if _rubik_cache.has(clave):
		return _rubik_cache[clave]
	var ts := TextServerManager.get_primary_interface()
	var fv := FontVariation.new()
	fv.base_font = load(RUTA_RUBIK)
	fv.variation_opentype = {ts.name_to_tag("wght"): peso}
	if tabular:
		fv.opentype_features = {ts.name_to_tag("tnum"): 1}
	var emoji := _emoji()
	# Fallback: la fuente de emoji y, detrás, la fuente por defecto (que es
	# la que hoy dibuja ♥ y otros símbolos).
	var fbs : Array[Font] = []
	if emoji:
		fbs.append(emoji)
	if ThemeDB.fallback_font:
		fbs.append(ThemeDB.fallback_font)
	fv.fallbacks = fbs
	_rubik_cache[clave] = fv
	return fv


static func pixel() -> Font:
	if _pixel == null:
		_pixel = load(RUTA_PIXEL) as Font
	return _pixel


static func label(texto: String, tam: int, color: Color, peso: int = 400, es_pixel: bool = false, tabular: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", pixel() if es_pixel else rubik(peso, tabular))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l
