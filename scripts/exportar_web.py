#!/usr/bin/env python3
"""Exporta el juego a web y lo deja listo para publicar en GitHub Pages.

Uso (desde la raíz del repo):

    python scripts/exportar_web.py

Hace tres cosas que el export de Godot por sí solo no hace:

1. Exporta a docs/juego/ con el preset "Web".

2. Le pone una versión al .pck (index.pck?v=<hash>). Esto es lo importante:
   GitHub Pages manda Cache-Control: max-age=600, así que el navegador se
   queda con el .pck viejo aunque el index.html sea nuevo. El resultado es
   un juego a medio actualizar — HTML nuevo, código viejo — que parece un
   bug del juego y no lo es. Como el nombre del archivo nunca cambia entre
   builds, hay que cambiar la URL a mano.

   El .wasm NO se versiona a propósito: pesa 39 MB y solo cambia cuando se
   actualiza Godot, así que conviene que el navegador lo siga cacheando.

3. Recrea .nojekyll (para que Pages no procese la carpeta con Jekyll) y
   .gdignore (para que el editor de Godot no importe el propio build como
   recursos del juego).
"""

import hashlib
import pathlib
import re
import shutil
import subprocess
import sys

RAIZ    = pathlib.Path(__file__).resolve().parent.parent
DESTINO = RAIZ / "docs" / "juego"
PRESET  = "Web"


def buscar_godot() -> str:
    """Devuelve el ejecutable de Godot, o termina con un mensaje claro."""
    candidatos = [
        shutil.which("godot"),
        shutil.which("godot4"),
        r"C:\Users\edward\OneDrive\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe",
    ]
    for c in candidatos:
        if c and pathlib.Path(c).exists():
            return c
    sys.exit(
        "No encontré el ejecutable de Godot.\n"
        "Ponelo en el PATH como 'godot', o editá buscar_godot() en este archivo."
    )


def exportar(godot: str) -> None:
    DESTINO.mkdir(parents=True, exist_ok=True)
    print(f"Exportando a {DESTINO} ...")
    res = subprocess.run(
        [godot, "--headless", "--path", str(RAIZ),
         "--export-release", PRESET, str(DESTINO / "index.html")],
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        print(res.stdout[-2000:])
        print(res.stderr[-2000:])
        sys.exit(f"El export falló (código {res.returncode}).")


def versionar_pck() -> str:
    """Reescribe index.html para que pida index.pck?v=<hash del pck>."""
    pck  = DESTINO / "index.pck"
    html = DESTINO / "index.html"
    version = hashlib.sha1(pck.read_bytes()).hexdigest()[:12]

    texto = html.read_text(encoding="utf-8")
    # Godot escribe "executable":"index" y deriva index.pck de ahí. Al
    # agregar mainPack explícitamente, el motor usa esa URL tal cual.
    texto = re.sub(r'"mainPack":"[^"]*",?', "", texto)
    texto = texto.replace(
        '"executable":"index"',
        f'"executable":"index","mainPack":"index.pck?v={version}"',
        1,
    )
    html.write_text(texto, encoding="utf-8")
    return version


def marcadores() -> None:
    (DESTINO / ".nojekyll").touch()
    (DESTINO / ".gdignore").touch()


def verificar_secretos() -> None:
    """El .pck no debe llevarse archivos que no son del juego.

    Ya pasó una vez: el export empaquetó .mcp.json con el token de
    administración de Supabase adentro. El índice de rutas del .pck se
    guarda sin comprimir, así que se puede revisar directamente (buscar el
    token como texto NO sirve: el contenido sí va comprimido).
    """
    data = (DESTINO / "index.pck").read_bytes()
    rutas = {m.decode("latin1")
             for m in re.findall(rb"res://[A-Za-z0-9_./\-]{3,80}", data)}
    sospechosas = sorted(
        r for r in rutas
        if r.endswith(".json") or "mcp" in r.lower()
        or r.startswith("res://docs") or r.startswith("res://supabase")
    )
    if sospechosas:
        print("\n*** SE EMPAQUETARON ARCHIVOS QUE NO DEBERÍAN IR ***")
        for r in sospechosas:
            print("   ", r)
        sys.exit("Revisá exclude_filter en export_presets.cfg antes de publicar.")
    print(f"Verificado: {len(rutas)} archivos empaquetados, ninguno sensible.")


PESO_ESPERADO_MB = 2.0
"""Techo del .pck. Los estudiantes lo descargan por internet en cada
partida, así que un salto de peso es un problema, no un detalle.

Ya pasó dos veces que una imagen sin usar se empaquetara igual: el export
va con export_filter="all_resources", o sea que mete TODO lo que esté en
el proyecto, la referencie alguien o no. mapa_campus_urbe.png (2,4 MB) se
descargó durante meses sin dibujarse nunca, y urbe_removed (1).png
(6,8 MB, el mapa nuevo todavía sin usar) casi duplica el build.

Y una tercera vez el problema no fue un archivo de más sino su AJUSTE de
importación: login_fondo.png entraba como textura sin pérdida y ocupaba
3,37 MB de un .pck de 4,6 MB. El 76 % de lo que cada estudiante bajaba era
la ilustración del login. Con compress/mode=1 (con pérdida, calidad 0,85)
quedó en 0,30 MB, con una diferencia media de 1,3/255 a la resolución en
que se ve: invisible. El techo bajó de 5,5 a 2,0 MB por eso — con 4,6 MB
de techo, un descuido de este tamaño vuelve a pasar sin que nadie se
entere.

Si este chequeo salta: puede ser un archivo que sobra (se agrega a
exclude_filter en export_presets.cfg) o una textura mal importada
(revisar compress/mode en su .import). Subir el techo es la última
opción, no la primera.
"""


def verificar_peso() -> None:
    mb = (DESTINO / "index.pck").stat().st_size / 1e6
    if mb > PESO_ESPERADO_MB:
        print()
        print(f"*** EL .pck PESA {mb:.1f} MB (esperado <= {PESO_ESPERADO_MB} MB) ***")
        print("    Suele ser un asset que nadie usa pero que el export empaqueta igual.")
        print("    Revisá assets/ y exclude_filter en export_presets.cfg.")
        sys.exit("No publiques sin entender de dónde salió el peso.")


CSS_CANVAS_GODOT = ("canvas{display:block;position:absolute;top:50%;left:50%;"
                    "transform:translate(-50%,-50%);width:min(100vw,calc(100vh*16/9));"
                    "height:min(100vh,calc(100vw*9/16))}")

CSS_CANVAS_NUESTRO = "canvas{display:block;position:absolute;top:0;left:0;width:100vw;height:100vh}"


def parchear_canvas() -> None:
    """Quita el centrado del shell de Godot, que pelea con canvas_resize_policy=2.

    Con la política 2 ("Adaptive") el motor hace dos cosas en su propio
    JavaScript: fuerza `position:absolute; top:0; left:0` sobre el lienzo, y en
    cada updateSize() le escribe `style.width`/`style.height` en píxeles del
    tamaño de la ventana. Lo que NO hace es borrar el
    `transform:translate(-50%,-50%)` que trae su plantilla para centrar, así
    que el lienzo termina corrido media pantalla hacia arriba y a la izquierda.

    (Con la política 1, el mismo updateSize() escribía 1280x720 px fijos y
    pisaba el `width:min(100vw,...)` de la plantilla: por eso en pantallas de
    laptop el borde inferior quedaba fuera. Ese era el problema original.)

    El reemplazo deja el lienzo ocupando la ventana entera. El escalado del
    juego lo resuelve Godot con stretch/mode=canvas_items y aspect=expand, que
    ya estaban bien configurados.

    Si algún día Godot cambia su plantilla, el assert corta la exportación en
    vez de publicar una pantalla rota sin que nadie se entere.
    """
    ruta = DESTINO / "index.html"
    html = ruta.read_text(encoding="utf-8")
    if CSS_CANVAS_NUESTRO in html:
        print("Lienzo: ya estaba parcheado.")
        return
    if CSS_CANVAS_GODOT not in html:
        sys.exit("El CSS del lienzo en index.html no es el esperado: revisar "
                 "parchear_canvas() en este script antes de publicar.")
    ruta.write_text(html.replace(CSS_CANVAS_GODOT, CSS_CANVAS_NUESTRO, 1), encoding="utf-8")
    print("Lienzo: centrado del shell reemplazado por ventana completa.")


def main() -> None:
    godot = buscar_godot()
    exportar(godot)
    verificar_secretos()
    verificar_peso()
    parchear_canvas()
    version = versionar_pck()
    marcadores()
    mb = (DESTINO / "index.pck").stat().st_size / 1e6
    print(f"\nListo. index.pck = {mb:.1f} MB, versión {version}")
    print("Ahora: git add docs/juego && git commit && git push (a main).")


if __name__ == "__main__":
    main()
