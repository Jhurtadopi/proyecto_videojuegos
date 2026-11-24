# Genera los sprites de los elementos de nivel (pixel art hecho por código) en arte_generado/nivel/.
# Luego: python3 aplicar_sprites.py  (los registra como spr_nivel_<nombre>, origen abajo-centro).
#   pinchos_0            32x16  fila de dos púas (se repite al dibujar)
#   boton_0/1            32x12  sin pulsar (rojo) / pulsado (verde)
#   checkpoint_0/1       24x64  apagado / encendido
#   plataforma_0         96x20  plataforma colgante de la grúa
#   puerta_0             32x128 compuerta de energía
#   meta_0/1             64x96  portal de salida (2 cuadros de brillo)
#   tile_0/1/2           32x32  terreno: superficie / relleno / relleno con detalle
#   llave_0/1            32x16  llave que suelta el minijefe (2 cuadros de brillo)
#   cerradura_0          32x128 puerta blindada con cerradura (se abre con la llave)
import os
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(AQUI, "nivel")
os.makedirs(OUT, exist_ok=True)

NEGRO = (14, 14, 22, 255)
ACERO_O = (52, 58, 74, 255)
ACERO = (86, 94, 116, 255)
ACERO_C = (138, 148, 172, 255)
CIAN = (0, 230, 255, 255)
CIAN_O = (0, 120, 150, 255)
MAGENTA = (230, 40, 160, 255)
ROJO = (230, 40, 50, 255)
ROJO_O = (120, 20, 30, 255)
VERDE = (60, 230, 120, 255)
VERDE_O = (20, 110, 60, 255)
AMARILLO = (250, 200, 40, 255)


def nuevo(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def guardar(im, nombre):
    im.save(os.path.join(OUT, nombre + ".png"))


# --- Pinchos: dos púas de 16x16 con punta roja ---
im = nuevo(32, 16); d = ImageDraw.Draw(im)
for ox in (0, 16):
    d.polygon([(ox, 15), (ox + 7, 1), (ox + 8, 1), (ox + 15, 15)], fill=ACERO, outline=NEGRO)
    d.line([(ox + 8, 3), (ox + 12, 13)], fill=ACERO_C)          # brillo
    d.line([(ox + 6, 4), (ox + 3, 12)], fill=ACERO_O)
    d.point([(ox + 7, 1), (ox + 8, 1), (ox + 7, 2), (ox + 8, 2)], fill=ROJO)
d.line([(0, 15), (31, 15)], fill=NEGRO)
guardar(im, "pinchos_0")

# --- Botón de suelo ---
for i, (cap, cap_o, alto) in enumerate([(ROJO, ROJO_O, 6), (VERDE, VERDE_O, 3)]):
    im = nuevo(32, 12); d = ImageDraw.Draw(im)
    d.rectangle([0, 7, 31, 11], fill=ACERO_O, outline=NEGRO)
    d.line([(2, 8), (29, 8)], fill=ACERO)
    top = 7 - alto
    d.rectangle([6, top, 25, 7], fill=cap, outline=NEGRO)
    d.line([(8, top + 1), (23, top + 1)], fill=(255, 255, 255, 160) if i == 0 else (200, 255, 220, 200))
    d.line([(7, 7), (24, 7)], fill=cap_o)
    guardar(im, "boton_%d" % i)

# --- Checkpoint: poste con bandera y luz ---
for i in range(2):
    im = nuevo(24, 64); d = ImageDraw.Draw(im)
    d.rectangle([2, 58, 21, 63], fill=ACERO_O, outline=NEGRO)       # base
    d.rectangle([4, 6, 7, 58], fill=ACERO, outline=NEGRO)           # poste
    d.line([(5, 8), (5, 56)], fill=ACERO_C)
    col = CIAN if i else (90, 90, 110, 255)
    col_o = CIAN_O if i else (50, 50, 64, 255)
    d.polygon([(8, 8), (22, 12), (8, 18)], fill=col, outline=NEGRO)  # bandera
    d.line([(9, 10), (16, 12)], fill=(255, 255, 255, 200) if i else (130, 130, 150, 255))
    d.ellipse([2, 0, 9, 7], fill=col_o, outline=NEGRO)              # luz
    d.point([(4, 2), (5, 2)], fill=(255, 255, 255, 255) if i else (120, 120, 140, 255))
    guardar(im, "checkpoint_%d" % i)

# --- Plataforma de la grúa (sin argolla: el cable lo dibuja la grúa) ---
im = nuevo(96, 20); d = ImageDraw.Draw(im)
d.rectangle([0, 0, 95, 19], fill=ACERO_O, outline=NEGRO)
d.rectangle([1, 1, 94, 6], fill=AMARILLO)
for x in range(-6, 96, 12):                                         # franjas de peligro
    d.polygon([(x, 6), (x + 6, 1), (x + 11, 1), (x + 5, 6)], fill=NEGRO)
d.line([(1, 7), (94, 7)], fill=NEGRO)
d.line([(2, 9), (93, 9)], fill=ACERO)
for x in range(6, 96, 14):
    d.point([(x, 14), (x + 1, 14)], fill=ACERO_C)                   # remaches
d.line([(1, 18), (94, 18)], fill=(30, 32, 44, 255))
guardar(im, "plataforma_0")

# --- Compuerta de energía ---
im = nuevo(32, 128); d = ImageDraw.Draw(im)
d.rectangle([0, 0, 31, 127], fill=(30, 24, 40, 255), outline=NEGRO)
d.rectangle([0, 0, 31, 7], fill=ACERO, outline=NEGRO)
d.rectangle([0, 120, 31, 127], fill=ACERO, outline=NEGRO)
for x in (6, 15, 24):
    d.rectangle([x, 8, x + 2, 119], fill=MAGENTA)
    d.line([(x + 1, 8), (x + 1, 119)], fill=(255, 170, 230, 255))
for y in range(14, 120, 16):
    d.line([(1, y), (30, y)], fill=(120, 20, 90, 255))
guardar(im, "puerta_0")

# --- Meta: portal ---
for i in range(2):
    im = nuevo(64, 96); d = ImageDraw.Draw(im)
    d.rectangle([0, 88, 63, 95], fill=ACERO_O, outline=NEGRO)
    d.rectangle([2, 4, 11, 88], fill=ACERO, outline=NEGRO)
    d.rectangle([52, 4, 61, 88], fill=ACERO, outline=NEGRO)
    d.rectangle([2, 0, 61, 9], fill=ACERO, outline=NEGRO)
    for y in range(14, 86, 12):
        d.rectangle([4, y, 9, y + 3], fill=CIAN if (y // 12 + i) % 2 else CIAN_O)
        d.rectangle([54, y, 59, y + 3], fill=CIAN if (y // 12 + i) % 2 == 0 else CIAN_O)
    d.rectangle([12, 10, 51, 87], fill=(0, 60, 90, 200))
    for k in range(6):
        y = 14 + ((k * 13 + i * 6) % 70)
        d.line([(16, y), (47, y)], fill=(120, 245, 255, 220))
    guardar(im, "meta_%d" % i)

# --- Terreno: superficie con borde de neón y relleno de paneles ---
def panel(d, detalle):
    d.rectangle([0, 0, 31, 31], fill=(34, 36, 50, 255))
    d.rectangle([0, 0, 31, 31], outline=(22, 22, 32, 255))
    d.line([(1, 1), (30, 1)], fill=(48, 52, 70, 255))
    d.line([(1, 1), (1, 30)], fill=(44, 48, 64, 255))
    if detalle:
        d.rectangle([9, 11, 22, 20], outline=(50, 54, 74, 255))
        d.point([(11, 13), (20, 18)], fill=(60, 66, 90, 255))
    else:
        d.point([(4, 4), (27, 4), (4, 27), (27, 27)], fill=(60, 66, 90, 255))

im = nuevo(32, 32); d = ImageDraw.Draw(im)
panel(d, False)
d.rectangle([0, 0, 31, 5], fill=(58, 64, 88, 255))
d.line([(0, 0), (31, 0)], fill=CIAN)
d.line([(0, 1), (31, 1)], fill=CIAN_O)
d.line([(0, 5), (31, 5)], fill=(22, 22, 32, 255))
guardar(im, "tile_0")
im = nuevo(32, 32); d = ImageDraw.Draw(im); panel(d, False); guardar(im, "tile_1")
im = nuevo(32, 32); d = ImageDraw.Draw(im); panel(d, True); guardar(im, "tile_2")
print("sprites de nivel en", OUT)


# --- Llave (la suelta el minijefe): dorada, con gema cian en el ojo ---
ORO = (250, 196, 40, 255)
ORO_C = (255, 240, 150, 255)
ORO_O = (160, 104, 20, 255)
for i in range(2):
    im = nuevo(32, 16); d = ImageDraw.Draw(im)
    d.ellipse([0, 1, 13, 14], fill=ORO, outline=NEGRO)                 # ojo
    d.ellipse([4, 5, 9, 10], fill=CIAN if i == 0 else (160, 250, 255, 255), outline=NEGRO)   # gema
    d.arc([1, 2, 12, 13], 200, 290, fill=ORO_C)
    d.rectangle([12, 6, 30, 9], fill=ORO, outline=NEGRO)               # caña
    d.line([(13, 7), (29, 7)], fill=ORO_C)
    d.rectangle([21, 9, 23, 13], fill=ORO, outline=NEGRO)              # dientes
    d.rectangle([26, 9, 28, 14], fill=ORO, outline=NEGRO)
    d.line([(14, 8), (29, 8)], fill=ORO_O)
    if i == 1:
        d.point([(3, 3), (17, 6), (27, 6)], fill=(255, 255, 255, 255))
    guardar(im, "llave_%d" % i)

# --- Puerta con cerradura: plancha blindada con bandas doradas y una cerradura grande en el centro ---
im = nuevo(32, 128); d = ImageDraw.Draw(im)
d.rectangle([0, 0, 31, 127], fill=ACERO_O, outline=NEGRO)
for y in range(4, 124, 12):                                            # remaches y paneles
    d.line([(1, y), (30, y)], fill=(40, 44, 58, 255))
    d.point([(3, y + 2), (28, y + 2)], fill=ACERO_C)
d.line([(2, 1), (2, 126)], fill=ACERO)
d.line([(29, 1), (29, 126)], fill=(36, 40, 52, 255))
for y in (14, 108):                                                    # bandas doradas
    d.rectangle([0, y, 31, y + 5], fill=ORO, outline=NEGRO)
    d.line([(1, y + 1), (30, y + 1)], fill=ORO_C)
    d.line([(1, y + 4), (30, y + 4)], fill=ORO_O)
d.rectangle([5, 46, 26, 82], fill=ORO, outline=NEGRO)                  # placa de la cerradura
d.rectangle([7, 48, 24, 80], fill=ORO_O)
d.rectangle([8, 49, 23, 79], fill=ORO)
d.line([(8, 49), (23, 49)], fill=ORO_C)
d.ellipse([11, 54, 20, 63], fill=NEGRO)                                # ojo de la cerradura
d.polygon([(13, 61), (18, 61), (20, 74), (11, 74)], fill=NEGRO)
d.point([(15, 57), (16, 57)], fill=(60, 60, 80, 255))
d.point([(10, 52), (21, 52), (10, 77), (21, 77)], fill=ORO_C)          # tornillos
d.rectangle([12, 84, 19, 87], fill=ROJO, outline=NEGRO)                # piloto: cerrada
guardar(im, "cerradura_0")
