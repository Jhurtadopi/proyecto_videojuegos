# Uso: python3 procesar_hoja.py originales/hoja.png [alto_personaje=63]
#      python3 procesar_hoja.py --fila NOMBRE originales/hoja.png [alto_personaje=63]
#        (1 fila: cuadro 1 = idle de referencia para la escala, cuadros 2..N = NOMBRE_0, NOMBRE_1...)
#        --ataque equivale a --fila ataque. Ej.: --fila gancho para las poses del gancho.
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

frames = []
for (y0, y1) in segs(fg.any(axis=1), 20):
    for (x0, x1) in segs(fg[y0:y1 + 1].any(axis=0), 8):
        ys, xs = np.where(fg[y0:y1 + 1, x0:x1 + 1])
        by0, by1, bx0, bx1 = ys.min() + y0, ys.max() + y0, xs.min() + x0, xs.max() + x0
        hh = int((by1 - by0) * 0.18)
        ax = np.where(fg[by0:by0 + hh + 1, bx0:bx1 + 1])[1].mean() + bx0   # ancla: la cabeza
        frames.append(((bx0, by0, bx1, by1), ax))
if ATAQUE:
    if len(frames) < 2: sys.exit("La hoja necesita al menos 2 cuadros (referencia + poses)")
    s = TARGET_H / (frames[0][0][3] - frames[0][0][1])        # escala medida con el idle de referencia
    frames = frames[1:]
    names = ["%s_%d" % (FILA, i) for i in range(len(frames))]
    VIEJOS = os.path.join(AQUI, "respaldo", FILA + "_anterior"); os.makedirs(VIEJOS, exist_ok=True)
    for f in os.listdir(OUT):                                   # aparta los cuadros anteriores de esa fila
        if f.startswith(FILA + "_"): os.replace(os.path.join(OUT, f), os.path.join(VIEJOS, f))
else:
    if len(frames) != 12:
        sys.exit("Se esperaban 12 cuadros y se encontraron %d" % len(frames))
    s = TARGET_H / np.median([b[3] - b[1] for b, _ in frames[:4]])
    names = ["idle_0", "idle_1", "idle_2", "idle_3", "salto_0", "salto_1",
             "correr_0", "correr_1", "correr_2", "correr_3", "dash_0", "ataque_0"]
base = np.dstack([a[..., :3], fg * 255]).astype(np.uint8)
im = Image.fromarray(base, "RGBA")
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
    small.append((o, (ax - bx0) * s))

pix = np.concatenate([o[o[..., 3] > 0][:, :3] for o, _ in small])
pal = Image.fromarray(pix.reshape(-1, 1, 3)).quantize(colors=24, method=Image.MEDIANCUT)
half = int(np.ceil(max(max(ax, o.shape[1] - ax) for o, ax in small)))
CW = half * 2; CH = max(o.shape[0] for o, _ in small)
# Si ya hay una animación de ataque de varios cuadros, la hoja general no pisa ataque_0
if not ATAQUE and os.path.exists(os.path.join(OUT, "ataque_1.png")):
    small, names = small[:-1], names[:-1]
for (o, ax), nm in zip(small, names):
    q = np.asarray(Image.fromarray(o[..., :3]).quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB"))
    c = np.zeros((CH, CW, 4), np.uint8)
    ox = int(round(CW / 2 - ax)); oy = CH - o.shape[0]
    c[oy:oy + o.shape[0], ox:ox + o.shape[1]] = np.dstack([q, o[..., 3]])
    Image.fromarray(c, "RGBA").save(os.path.join(OUT, nm + ".png"))
print("%d cuadros de %dx%d en %s" % (len(names), CW, CH, OUT))
