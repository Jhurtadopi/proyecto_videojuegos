# Uso: python3 procesar_hoja.py originales/hoja.png [alto_personaje=63]
#      python3 procesar_hoja.py --fila NOMBRE originales/hoja.png [alto_personaje=63]
#        (1 fila: cuadro 1 = idle de referencia para la escala, cuadros 2..N = NOMBRE_0, NOMBRE_1...)
#        --ataque equivale a --fila ataque. Ej.: --fila gancho para las poses del gancho.
#        Varias animaciones en la misma fila: --fila lanzador:2,aereo:2,estampada:2
# Corta una hoja de 2 filas x 6 cuadros (idle x4, salto x2 / correr x4, dash, ataque),
# la escala a pixel art y deja los PNG en arte_generado/jugador/. Luego: python3 aplicar_sprites.py
# Acepta hojas con fondo transparente (Higgsfield) o con fondo blanco liso.
import os, sys, numpy as np
from PIL import Image, ImageDraw
AQUI = os.path.dirname(os.path.abspath(__file__))
args = sys.argv[1:]
FILA = None
if "--ataque" in args:
    FILA = "ataque"; args.remove("--ataque")
if "--fila" in args:
    i = args.index("--fila"); FILA = args[i + 1]; del args[i:i + 2]
ATAQUE = FILA is not None
src = args[0]; TARGET_H = int(args[1]) if len(args) > 1 else 63
OUT = os.path.join(AQUI, "jugador"); os.makedirs(OUT, exist_ok=True)

im = Image.open(src).convert("RGBA")
a = np.asarray(im).astype(np.int32)
if (a[..., 3] < 250).mean() > 0.2:              # fondo transparente
    fg = a[..., 3] >= 128
else:                                            # fondo blanco: relleno desde los bordes
    m = Image.fromarray(((a[..., :3].min(axis=2) >= 232) * 255).astype(np.uint8))
    m = Image.merge("RGB", (m, m, m))
    for x, y in [(0, 0), (m.width - 1, 0), (0, m.height - 1), (m.width - 1, m.height - 1)]:
        if m.getpixel((x, y)) == (255, 255, 255): ImageDraw.floodfill(m, (x, y), (128, 128, 128))
    fg = np.asarray(m)[..., 0] != 128

def segs(v, gap):
    xs = np.where(v)[0]; out = []; s = p = xs[0]
    for x in xs[1:]:
        if x - p > gap: out.append((s, p)); s = x
        p = x
    out.append((s, p)); return out

# Cuadros esperados en una fila con varias animaciones ("a:2,b:3" -> 1 de referencia + 5)
ESPERADOS = None
if ATAQUE and ":" in FILA:
    ESPERADOS = 1 + sum(int(p.split(":")[1]) for p in FILA.split(","))

def separar(cols, banda, n):
    # Si dos poses se tocan (ej. la katana de una con la siguiente), parte el bloque más ancho
    # por la columna con menos píxeles, buscando en su parte central
    cols = list(cols)
    while len(cols) < n:
        i = max(range(len(cols)), key=lambda k: cols[k][1] - cols[k][0])
        a, b = cols[i]
        ini, fin = a + (b - a) // 4, b - (b - a) // 4
        cuenta = banda[:, ini:fin + 1].sum(axis=0)
        corte = ini + int(np.argmin(cuenta))
        cols[i:i + 1] = [(a, corte), (corte + 1, b)]
    return cols

frames = []
SEPARADO = False        # True si hubo que partir poses pegadas: solo entonces se limpian restos sueltos
for (y0, y1) in segs(fg.any(axis=1), 20):
    _cols = segs(fg[y0:y1 + 1].any(axis=0), 8)
    if ESPERADOS and len(_cols) < ESPERADOS:
        _cols = separar(_cols, fg[y0:y1 + 1], ESPERADOS)
        SEPARADO = True
    for (x0, x1) in _cols:
        ys, xs = np.where(fg[y0:y1 + 1, x0:x1 + 1])
        by0, by1, bx0, bx1 = ys.min() + y0, ys.max() + y0, xs.min() + x0, xs.max() + x0
        hh = int((by1 - by0) * 0.18)
        ax = np.where(fg[by0:by0 + hh + 1, bx0:bx1 + 1])[1].mean() + bx0   # ancla: la cabeza
        frames.append(((bx0, by0, bx1, by1), ax))
if ATAQUE:
    if len(frames) < 2: sys.exit("La hoja necesita al menos 2 cuadros (referencia + poses)")
    s = TARGET_H / (frames[0][0][3] - frames[0][0][1])        # escala medida con el idle de referencia
    frames = frames[1:]
    if ":" in FILA:                                             # "a:2,b:3" -> a_0 a_1 b_0 b_1 b_2
        partes = [(p.split(":")[0], int(p.split(":")[1])) for p in FILA.split(",")]
        names = ["%s_%d" % (n, i) for n, c in partes for i in range(c)]
        prefijos = [n for n, _ in partes]
        if len(names) != len(frames):
            sys.exit("La fila tiene %d cuadros (sin la referencia) y se pidieron %d" % (len(frames), len(names)))
    else:
        names = ["%s_%d" % (FILA, i) for i in range(len(frames))]
        prefijos = [FILA]
    for pre in prefijos:                                        # aparta los cuadros anteriores de cada animación
        VIEJOS = os.path.join(AQUI, "respaldo", pre + "_anterior"); os.makedirs(VIEJOS, exist_ok=True)
        for f in os.listdir(OUT):
            if f.startswith(pre + "_"): os.replace(os.path.join(OUT, f), os.path.join(VIEJOS, f))
else:
    if len(frames) != 12:
        sys.exit("Se esperaban 12 cuadros y se encontraron %d" % len(frames))
    s = TARGET_H / np.median([b[3] - b[1] for b, _ in frames[:4]])
    names = ["idle_0", "idle_1", "idle_2", "idle_3", "salto_0", "salto_1",
             "correr_0", "correr_1", "correr_2", "correr_3", "dash_0", "ataque_0"]
base = np.dstack([a[..., :3], fg * 255]).astype(np.uint8)
im = Image.fromarray(base, "RGBA")
def limpiar(o, ax, minimo=12):
    # Borra fragmentos sueltos: de menos de "minimo" px, o de menos de 60 px pegados al borde lateral
    # (restos de la pose vecina al separar)
    # y recorta los bordes vacíos, corrigiendo el ancla
    m = o[..., 3] > 0
    h, w = m.shape
    visto = np.zeros_like(m)
    for y in range(h):
        for x in range(w):
            if m[y, x] and not visto[y, x]:
                pila, comp = [(y, x)], []
                visto[y, x] = True
                while pila:
                    cy, cx = pila.pop(); comp.append((cy, cx))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not visto[ny, nx]:
                                visto[ny, nx] = True; pila.append((ny, nx))
                toca_borde = any(cx <= 1 or cx >= w - 2 for _, cx in comp)
                if len(comp) < minimo or (toca_borde and len(comp) < 60):
                    for cy, cx in comp: o[cy, cx, 3] = 0
    ys, xs = np.where(o[..., 3] > 0)
    if len(ys) == 0: return o, ax
    return o[ys.min():ys.max() + 1, xs.min():xs.max() + 1], ax - xs.min()

small = []
for (bx0, by0, bx1, by1), ax in frames:
    cr = np.asarray(im.crop((bx0, by0, bx1 + 1, by1 + 1))).astype(np.float32)
    w = max(1, round(cr.shape[1] * s)); h = max(1, round(cr.shape[0] * s))
    al = cr[..., 3:4] / 255
    pm = np.concatenate([cr[..., :3] * al, cr[..., 3:4]], -1)
    r = np.stack([np.asarray(Image.fromarray(pm[..., i]).resize((w, h), Image.BOX)) for i in range(4)], -1)
    A = r[..., 3]
    rgb = np.where(A[..., None] > 0, r[..., :3] / np.maximum(A[..., None] / 255, 1e-3), 0)
    o = np.zeros((h, w, 4), np.uint8); o[..., :3] = np.clip(rgb, 0, 255); o[..., 3] = (A >= 110) * 255
    # (sin separar se conservan los fragmentos sueltos: rocas, chispas, líneas de energía)
    small.append(limpiar(o, (ax - bx0) * s) if SEPARADO else (o, (ax - bx0) * s))

pix = np.concatenate([o[o[..., 3] > 0][:, :3] for o, _ in small])
pal = Image.fromarray(pix.reshape(-1, 1, 3)).quantize(colors=24, method=Image.MEDIANCUT)
half = int(np.ceil(max(max(ax, o.shape[1] - ax) for o, ax in small)))
CW = half * 2; CH = max(o.shape[0] for o, _ in small)
# Si ya hay una animación de ataque de varios cuadros, la hoja general no pisa ataque_0
if not ATAQUE and os.path.exists(os.path.join(OUT, "ataque_1.png")):
    small, names = small[:-1], names[:-1]
# En una fila con varias animaciones, cada animación tiene su propio lienzo (no se infla por la más grande)
lienzos = {}
if ATAQUE:
    for (o, ax), nm in zip(small, names):
        g = nm.rsplit("_", 1)[0]
        a = lienzos.get(g, (0, 0))
        lienzos[g] = (max(a[0], int(np.ceil(max(ax, o.shape[1] - ax)))), max(a[1], o.shape[0]))
for (o, ax), nm in zip(small, names):
    if ATAQUE:
        _half, CH = lienzos[nm.rsplit("_", 1)[0]]; CW = _half * 2
    q = np.asarray(Image.fromarray(o[..., :3]).quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB"))
    c = np.zeros((CH, CW, 4), np.uint8)
    ox = int(round(CW / 2 - ax)); oy = CH - o.shape[0]
    c[oy:oy + o.shape[0], ox:ox + o.shape[1]] = np.dstack([q, o[..., 3]])
    Image.fromarray(c, "RGBA").save(os.path.join(OUT, nm + ".png"))
if ATAQUE:
    for g, (hh, ch) in lienzos.items(): print("%s: %dx%d" % (g, hh * 2, ch))
print("%d cuadros en %s" % (len(names), OUT))
