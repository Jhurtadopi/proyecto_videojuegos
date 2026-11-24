# Crea/actualiza los sprites del jugador en el proyecto GameMaker a partir de arte_generado/jugador/*.png
import os, re, shutil, uuid
P = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(P, "arte_generado", "jugador")
BK = os.path.join(P, "arte_generado", "respaldo")
YYP = os.path.join(P, "Blank Pixel Game.yyp")

if not os.path.exists(BK):
    os.makedirs(BK)
    shutil.copytree(os.path.join(P, "sprites/spr_jugador"), os.path.join(BK, "spr_jugador"))
    shutil.copy(os.path.join(P, "objects/obj_jugador/obj_jugador.yy"), BK)
    shutil.copy(YYP, BK)

SPRITES = [
    ("spr_jugador",        ["idle_0", "idle_1", "idle_2", "idle_3"], 6),
    ("spr_jugador_correr", ["correr_0", "correr_1", "correr_2", "correr_3"], 10),
    ("spr_jugador_salto",  ["salto_0", "salto_1"], 6),
    ("spr_jugador_dash",   ["dash_0"], 10),
    ("spr_jugador_ataque", sorted([f[:-4] for f in os.listdir(ART) if f.startswith("ataque_") and f.endswith(".png")],
                                  key=lambda n: int(n.split("_")[1])), 10),
]
def cuadros(prefijo):
    return sorted([f[:-4] for f in os.listdir(ART) if f.startswith(prefijo + "_") and f.endswith(".png")],
                  key=lambda n: int(n.split("_")[-1]))

# Sprites opcionales: se crean solo si ya existen sus cuadros
for _nombre in ["gancho", "lanzador", "aereo", "estampada",
                "ud_idle", "ud_correr", "ud_ataque", "ud_excavar", "ud_emerger",
                "ud_arriba", "ud_subir",   # ud_ = estilo Underdog
                "gn_idle", "gn_correr", "gn_disparo", "gn_aire", "gn_deslizar"]:   # gn_ = estilo Gunner
    if cuadros(_nombre):
        SPRITES.append(("spr_jugador_" + _nombre, cuadros(_nombre), 6))

from PIL import Image

def copiar_si_cambia(src, dst):
    import filecmp
    if not os.path.exists(dst) or not filecmp.cmp(src, dst, shallow=False):
        shutil.copy(src, dst)

def frame_entry(f):
    return '    {"$GMSpriteFrame":"v1","%%Name":"%s","name":"%s","resourceType":"GMSpriteFrame","resourceVersion":"2.0",},\n' % (f, f)

def key_entry(name, f, i, kid):
    return ('            {"$Keyframe<SpriteFrameKeyframe>":"","Channels":{\n'
            '                "0":{"$SpriteFrameKeyframe":"","Id":{"name":"%s","path":"sprites/%s/%s.yy",},"resourceType":"SpriteFrameKeyframe","resourceVersion":"2.0",},\n'
            '              },"Disabled":false,"id":"%s","IsCreationKey":false,"Key":%d.0,"Length":1.0,"resourceType":"Keyframe<SpriteFrameKeyframe>","resourceVersion":"2.0","Stretch":false,},\n'
            ) % (f, name, name, kid, i)

def yy(name, frames, layer, fps, W, H, kids):
    return ('{\n  "$GMSprite":"v2",\n  "%%Name":"%(n)s",\n  "bboxMode":0,\n  "bbox_bottom":%(hb)d,\n  "bbox_left":0,\n  "bbox_right":%(wb)d,\n  "bbox_top":0,\n'
            '  "collisionKind":1,\n  "collisionTolerance":0,\n  "DynamicTexturePage":false,\n  "edgeFiltering":false,\n  "For3D":false,\n'
            '  "frames":[\n%(fr)s  ],\n  "gridX":0,\n  "gridY":0,\n  "height":%(h)d,\n  "HTile":false,\n'
            '  "layers":[\n    {"$GMImageLayer":"","%%Name":"%(l)s","blendMode":0,"displayName":"default","isLocked":false,"name":"%(l)s","opacity":100.0,"resourceType":"GMImageLayer","resourceVersion":"2.0","visible":true,},\n  ],\n'
            '  "name":"%(n)s",\n  "nineSlice":null,\n  "origin":7,\n  "parent":{\n    "name":"Blank Pixel Game",\n    "path":"Blank Pixel Game.yyp",\n  },\n'
            '  "preMultiplyAlpha":false,\n  "resourceType":"GMSprite",\n  "resourceVersion":"2.0",\n'
            '  "sequence":{\n    "$GMSequence":"v1",\n    "%%Name":"%(n)s",\n    "autoRecord":true,\n    "backdropHeight":768,\n    "backdropImageOpacity":0.5,\n    "backdropImagePath":"",\n    "backdropWidth":1366,\n    "backdropXOffset":0.0,\n    "backdropYOffset":0.0,\n'
            '    "events":{\n      "$KeyframeStore<MessageEventKeyframe>":"",\n      "Keyframes":[],\n      "resourceType":"KeyframeStore<MessageEventKeyframe>",\n      "resourceVersion":"2.0",\n    },\n'
            '    "eventStubScript":null,\n    "eventToFunction":{},\n    "length":%(len)d.0,\n    "lockOrigin":false,\n'
            '    "moments":{\n      "$KeyframeStore<MomentsEventKeyframe>":"",\n      "Keyframes":[],\n      "resourceType":"KeyframeStore<MomentsEventKeyframe>",\n      "resourceVersion":"2.0",\n    },\n'
            '    "name":"%(n)s",\n    "playback":1,\n    "playbackSpeed":%(fps)d.0,\n    "playbackSpeedType":0,\n    "resourceType":"GMSequence",\n    "resourceVersion":"2.0",\n    "showBackdrop":true,\n    "showBackdropImage":false,\n    "timeUnits":1,\n'
            '    "tracks":[\n      {"$GMSpriteFramesTrack":"","builtinName":0,"events":[],"inheritsTrackColour":true,"interpolation":1,"isCreationTrack":false,"keyframes":{"$KeyframeStore<SpriteFrameKeyframe>":"","Keyframes":[\n%(ks)s'
            '          ],"resourceType":"KeyframeStore<SpriteFrameKeyframe>","resourceVersion":"2.0",},"modifiers":[],"name":"frames","resourceType":"GMSpriteFramesTrack","resourceVersion":"2.0","spriteId":null,"trackColour":0,"tracks":[],"traits":0,},\n    ],\n'
            '    "visibleRange":null,\n    "volume":1.0,\n    "xorigin":%(xo)d,\n    "yorigin":%(h)d,\n  },\n'
            '  "swatchColours":null,\n  "swfPrecision":0.5,\n  "textureGroupId":{\n    "name":"Default",\n    "path":"texturegroups/Default",\n  },\n  "type":0,\n  "VTile":false,\n  "width":%(w)d,\n}'
            ) % dict(n=name, w=W, h=H, wb=W-1, hb=H-1, xo=W//2, l=layer, fps=fps, len=len(frames),
                     fr="".join(frame_entry(f) for f in frames),
                     ks="".join(key_entry(name, f, i, k) for i, (f, k) in enumerate(zip(frames, kids))))

proj = open(YYP).read()
for name, imgs, fps in SPRITES:
    d = os.path.join(P, "sprites", name)
    old = os.path.join(d, name + ".yy")
    frames, layer = [], None
    if os.path.exists(old):   # reutiliza los UUID existentes para no dejar archivos huérfanos
        t = open(old).read()
        frames = re.findall(r'\{"\$GMSpriteFrame":"v1","%Name":"([0-9a-f-]+)"', t)
        layer = re.search(r'"\$GMImageLayer":"","%Name":"([0-9a-f-]+)"', t).group(1)
    layer = layer or str(uuid.uuid4())
    # IDs de los fotogramas clave existentes: se reutilizan para no generar cambios en git
    kids = []
    if os.path.exists(old):
        kids = re.findall(r'"Disabled":false,"id":"([0-9a-f-]+)"', open(old).read())
    kids = (kids + [str(uuid.uuid4()) for _ in imgs])[:len(imgs)]
    frames = (frames + [str(uuid.uuid4()) for _ in imgs])[:len(imgs)]
    os.makedirs(d, exist_ok=True)
    for f, img in zip(frames, imgs):
        src = os.path.join(ART, img + ".png")
        copiar_si_cambia(src, os.path.join(d, f + ".png"))
        os.makedirs(os.path.join(d, "layers", f), exist_ok=True)
        copiar_si_cambia(src, os.path.join(d, "layers", f, layer + ".png"))
    W, H = Image.open(os.path.join(ART, imgs[0] + ".png")).size
    nuevo = yy(name, frames, layer, fps, W, H, kids)
    if not os.path.exists(old) or open(old).read() != nuevo:   # solo escribe si algo cambió
        open(old, "w").write(nuevo)
    if '"path":"sprites/%s/%s.yy"' % (name, name) not in proj:
        line = '    {"id":{"name":"%s","path":"sprites/%s/%s.yy",},},\n' % (name, name, name)
        anchor = '    {"id":{"name":"spr_proyectil"'
        proj = proj.replace(anchor, line + anchor, 1)
open(YYP, "w").write(proj)

# La máscara de colisión del jugador (32x64) NO se toca aquí: obj_jugador es de otros colaboradores.
# Se asigna en tiempo de ejecución desde obj_mecanicas_jugador (jugador.mask_index = spr_hurtbox).
print("listo")
