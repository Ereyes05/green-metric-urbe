# Todo emoji o símbolo (U+2000 en adelante: ✕ ✓ → ⌨ 🌿 …) que usa la UI está
# en alguna fuente que viaja con el juego: Rubik, la fuente por defecto, el
# recorte de NotoColorEmoji o los de símbolos (WindowManager). En el
# navegador no hay fuentes del sistema: uno que falte se ve como un cuadradito (docs/ESTADO_PROYECTO.md,
# "Emoji como cuadraditos"). Si esta prueba falla, regenerar el recorte.
# Correr: $GODOT --headless --path . res://tests/test_emojis.tscn
extends Node

const FUENTES := [
	"res://assets/fonts/NotoColorEmoji-subset.ttf",
	"res://assets/fonts/NotoSansMath-subset.ttf",
	"res://assets/fonts/NotoSansSymbols2-subset.ttf",
	"res://assets/fonts/Rubik-VariableFont_wght.ttf",
]
# Marcas de variación y unión de emoji: no se dibujan.
const INVISIBLES := [0x200D, 0xFE0E, 0xFE0F]

var _fallos := 0


func _scripts(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir.path_join(d), out)


func _ready() -> void:
	print("test_emojis")
	var fuentes : Array = FUENTES.map(func(r): return load(r))
	fuentes.append(ThemeDB.fallback_font)
	var archivos : Array = []
	_scripts("res://scenes", archivos)
	_scripts("res://autoload", archivos)
	var vistos := {}
	for ruta in archivos:
		for linea in FileAccess.get_file_as_string(ruta).split("\n"):
			if linea.strip_edges().begins_with("#"):
				continue
			for i in linea.length():
				var c := linea.unicode_at(i)
				if c >= 0x2000 and not c in INVISIBLES and not vistos.has(c):
					vistos[c] = ruta
	for c in vistos:
		if not fuentes.any(func(f): return f.has_char(c)):
			_fallos += 1
			printerr("  FALLA %s (U+%X) en %s no está en el recorte" % [String.chr(c), c, vistos[c]])
	print("  %d emoji revisados" % vistos.size())
	print("test_emojis: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
