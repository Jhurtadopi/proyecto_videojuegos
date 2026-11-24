# Genera los sprites extra del estilo Gunner (balas, iconos de HUD y armas en la mano)
# a partir de arte_generado/originales/{balas_gunner,hud_balas,armas_gunner}.png
# Cada hoja es una sola fila de iconos sueltos. A diferencia de procesar_hoja.py (personajes),
# aqui el origen de cada sprite va CENTRADO y cada icono se escala por su altura objetivo.
#
# Uso: python3 aplicar_gunner_extra.py
import os, re, uuid, numpy as np
from PIL import Image

P = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIG = os.path.join(P, "arte_generado", "originales")
YYP = os.path.join(P, "Blank Pixel Game.yyp")

# (hoja, [nombres por columna en orden], altura_objetivo_px)
HOJAS = [
    ("balas_gunner.png",  ["spr_gn_bala_pistola", "spr_gn_bala_escopeta", "spr_gn_bala_franco"], 12),
    ("hud_balas.png",     ["spr_gn_hud_pistola", "spr_gn_hud_escopeta", "spr_gn_hud_franco"], 18),
    ("armas_gunner.png",  ["spr_gn_arma_escopeta", "spr_gn_arma_franco"], 22),
]

def bands(v, gap):
    xs = np.where(v)[0]
    if len(xs) == 0: return []
    out = []; s = p = xs[0]
    for x in xs[1:]:
        if x - p > gap: out.append((s, p)); s = x
        p = x
    out.append((s, p)); return out

def recortar(hoja):
    im = Image.open(os.path.join(ORIG, hoja)).convert("RGBA")
    a = np.asarray(im)
    fg = a[..., 3] >= 128
    rb = bands(fg.any(axis=1), 20)
    y0, y1 = rb[0]
    cb = bands(fg[y0:y1 + 1].any(axis=0), 12)
    cajas = []
    for (x0, x1) in cb:
        ys, xs = np.where(fg[y0:y1 + 1, x0:x1 + 1])
        cajas.append((xs.min() + x0, ys.min() + y0, xs.max() + x0, ys.max() + y0))
    return im, cajas

def escalar(im, caja, alto_obj):
    bx0, by0, bx1, by1 = caja
    cr = im.crop((bx0, by0, bx1 + 1, by1 + 1))
    s = alto_obj / cr.height
    w = max(1, round(cr.width * s)); h = max(1, round(cr.height * s))
    # Escala premultiplicando el alfa para no ensuciar los bordes
    arr = np.asarray(cr).astype(np.float32)
    al = arr[..., 3:4] / 255
    pm = np.concatenate([arr[..., :3] * al, arr[..., 3:4]], -1)
    r = np.stack([np.asarray(Image.fromarray(pm[..., i]).resize((w, h), Image.BOX)) for i in range(4)], -1)
    A = r[..., 3]
    rgb = np.where(A[..., None] > 0, r[..., :3] / np.maximum(A[..., None] / 255, 1e-3), 0)
    o = np.zeros((h, w, 4), np.uint8)
    o[..., :3] = np.clip(rgb, 0, 255); o[..., 3] = (A >= 110) * 255
    return Image.fromarray(o, "RGBA")

# --- plantilla .yy con ORIGEN CENTRADO (origin 4 = centro) ---
def yy_centrado(name, frame, layer, W, H, kid):
    return ('{\n  "$GMSprite":"v2",\n  "%%Name":"%(n)s",\n  "bboxMode":0,\n  "bbox_bottom":%(hb)d,\n  "bbox_left":0,\n  "bbox_right":%(wb)d,\n  "bbox_top":0,\n'
            '  "collisionKind":1,\n  "collisionTolerance":0,\n  "DynamicTexturePage":false,\n  "edgeFiltering":false,\n  "For3D":false,\n'
            '  "frames":[\n    {"$GMSpriteFrame":"v1","%%Name":"%(f)s","name":"%(f)s","resourceType":"GMSpriteFrame","resourceVersion":"2.0",},\n  ],\n'
            '  "gridX":0,\n  "gridY":0,\n  "height":%(h)d,\n  "HTile":false,\n'
            '  "layers":[\n    {"$GMImageLayer":"","%%Name":"%(l)s","blendMode":0,"displayName":"default","isLocked":false,"name":"%(l)s","opacity":100.0,"resourceType":"GMImageLayer","resourceVersion":"2.0","visible":true,},\n  ],\n'
            '  "name":"%(n)s",\n  "nineSlice":null,\n  "origin":4,\n  "parent":{\n    "name":"Blank Pixel Game",\n    "path":"Blank Pixel Game.yyp",\n  },\n'
            '  "preMultiplyAlpha":false,\n  "resourceType":"GMSprite",\n  "resourceVersion":"2.0",\n'
            '  "sequence":{\n    "$GMSequence":"v1",\n    "%%Name":"%(n)s",\n    "autoRecord":true,\n    "backdropHeight":768,\n    "backdropImageOpacity":0.5,\n    "backdropImagePath":"",\n    "backdropWidth":1366,\n    "backdropXOffset":0.0,\n    "backdropYOffset":0.0,\n'
            '    "events":{\n      "$KeyframeStore<MessageEventKeyframe>":"",\n      "Keyframes":[],\n      "resourceType":"KeyframeStore<MessageEventKeyframe>",\n      "resourceVersion":"2.0",\n    },\n'
            '    "eventStubScript":null,\n    "eventToFunction":{},\n    "length":1.0,\n    "lockOrigin":false,\n'
            '    "moments":{\n      "$KeyframeStore<MomentsEventKeyframe>":"",\n      "Keyframes":[],\n      "resourceType":"KeyframeStore<MomentsEventKeyframe>",\n      "resourceVersion":"2.0",\n    },\n'
            '    "name":"%(n)s",\n    "playback":1,\n    "playbackSpeed":6.0,\n    "playbackSpeedType":0,\n    "resourceType":"GMSequence",\n    "resourceVersion":"2.0",\n    "showBackdrop":true,\n    "showBackdropImage":false,\n    "timeUnits":1,\n'
            '    "tracks":[\n      {"$GMSpriteFramesTrack":"","builtinName":0,"events":[],"inheritsTrackColour":true,"interpolation":1,"isCreationTrack":false,"keyframes":{"$KeyframeStore<SpriteFrameKeyframe>":"","Keyframes":[\n'
            '            {"$Keyframe<SpriteFrameKeyframe>":"","Channels":{\n'
            '                "0":{"$SpriteFrameKeyframe":"","Id":{"name":"%(f)s","path":"sprites/%(n)s/%(n)s.yy",},"resourceType":"SpriteFrameKeyframe","resourceVersion":"2.0",},\n'
            '              },"Disabled":false,"id":"%(kid)s","IsCreationKey":false,"Key":0.0,"Length":1.0,"resourceType":"Keyframe<SpriteFrameKeyframe>","resourceVersion":"2.0","Stretch":false,},\n'
            '          ],"resourceType":"KeyframeStore<SpriteFrameKeyframe>","resourceVersion":"2.0",},"modifiers":[],"name":"frames","resourceType":"GMSpriteFramesTrack","resourceVersion":"2.0","spriteId":null,"trackColour":0,"tracks":[],"traits":0,},\n    ],\n'
            '    "visibleRange":null,\n    "volume":1.0,\n    "xorigin":%(xo)d,\n    "yorigin":%(yo)d,\n  },\n'
            '  "swatchColours":null,\n  "swfPrecision":0.5,\n  "textureGroupId":{\n    "name":"Default",\n    "path":"texturegroups/Default",\n  },\n  "type":0,\n  "VTile":false,\n  "width":%(w)d,\n}'
            ) % dict(n=name, f=frame, l=layer, w=W, h=H, wb=W - 1, hb=H - 1, xo=W // 2, yo=H // 2, kid=kid)

def copiar_si_cambia(img, dst):
    import filecmp, tempfile
    tmp = dst + ".tmp.png"
    img.save(tmp)
    if not os.path.exists(dst) or not filecmp.cmp(tmp, dst, shallow=False):
        os.replace(tmp, dst)
    else:
        os.remove(tmp)

proj = open(YYP).read()

for hoja, nombres, alto in HOJAS:
    im, cajas = recortar(hoja)
    if len(cajas) != len(nombres):
        raise SystemExit("%s: %d iconos, se esperaban %d" % (hoja, len(cajas), len(nombres)))
    for caja, name in zip(cajas, nombres):
        o = escalar(im, caja, alto)
        d = os.path.join(P, "sprites", name)
        old = os.path.join(d, name + ".yy")
        # Reutiliza UUIDs existentes para no romper referencias ni ensuciar git
        frame = layer = kid = None
        if os.path.exists(old):
            t = open(old).read()
            m = re.search(r'\{"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"', t); frame = m.group(1) if m else None
            m = re.search(r'"\$GMImageLayer":"","%Name":"([0-9a-f-]+)"', t); layer = m.group(1) if m else None
            m = re.search(r'"Disabled":false,"id":"([0-9a-f-]+)"', t); kid = m.group(1) if m else None
        frame = frame or str(uuid.uuid4())
        layer = layer or str(uuid.uuid4())
        kid = kid or str(uuid.uuid4())
        os.makedirs(os.path.join(d, "layers", frame), exist_ok=True)
        copiar_si_cambia(o, os.path.join(d, frame + ".png"))
        copiar_si_cambia(o, os.path.join(d, "layers", frame, layer + ".png"))
        W, H = o.size
        nuevo = yy_centrado(name, frame, layer, W, H, kid)
        if not os.path.exists(old) or open(old).read() != nuevo:
            open(old, "w").write(nuevo)
        linea = '    {"id":{"name":"%s","path":"sprites/%s/%s.yy",},},\n' % (name, name, name)
        if '"path":"sprites/%s/%s.yy"' % (name, name) not in proj:
            ancla = '    {"id":{"name":"spr_proyectil"'
            proj = proj.replace(ancla, linea + ancla, 1)
        print("%s  %dx%d" % (name, W, H))

open(YYP, "w").write(proj)
print("listo")
