# Genera las rooms de los niveles (Nivel_1, Nivel_2) a partir de su descripción en este archivo.
# Correr desde Blank Pixel Game/arte_generado con GameMaker CERRADO:  python3 generar_niveles.py
# Deja una vista previa en arte_generado/niveles/preview_<nivel>.png
#
# Cuadrícula de 32 px: columnas (c) de izquierda a derecha, filas (r) de arriba abajo.
# "piso" = fila del primer bloque sólido bajo los pies (los objetos se apoyan en piso*32).
# Para cambiar un nivel: editar su función nivel_N() y volver a correr el script.
import os, json, re, hashlib

P = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
YYP = os.path.join(P, "Blank Pixel Game.yyp")
PREV = os.path.join(P, "arte_generado", "niveles")
T = 32

ENEMIGOS = {"L": "obj_enemigo_ligero", "M": "obj_enemigo_mediano", "H": "obj_enemigo_pesado", "T": "obj_torreta"}


class Nivel:
    def __init__(self, nombre, cols, filas=30, titulo="", subtitulo="", cielo=((10, 10, 26), (46, 16, 58))):
        self.nombre, self.cols, self.filas = nombre, cols, filas
        self.g = [[" "] * cols for _ in range(filas)]
        self.inst = []          # (objeto, x, y, sx, sy, codigo)
        self.extra = []         # para la vista previa
        self.titulo, self.subtitulo, self.cielo = titulo or nombre, subtitulo, cielo

    def solido(self, c0, c1, r0, r1):
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                self.g[r][c] = "#"

    def hueco(self, c0, c1, r0, r1):
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                self.g[r][c] = " "

    def arena(self, c0, c1, r0, r1, canal, mensaje=None, jefe=None, cierre=None, premio=None):
        cod = "ancho = %d;\nalto = %d;\ncanal = %d;\n" % ((c1 - c0 + 1) * T, (r1 - r0 + 1) * T, canal)
        if mensaje: cod += 'mensaje = "%s";\n' % mensaje
        if jefe: cod += 'jefe_nombre = "%s";\n' % jefe
        if cierre is not None: cod += "canal_cierre = %d;\n" % cierre
        if premio: cod += "premio = %s;\n" % premio
        self.inst.append(("obj_arena", c0 * T, r0 * T, 1, 1, cod))

    def pinchos(self, c0, c1, r):
        for c in range(c0, c1 + 1):
            self.g[r][c] = "^"

    def _pon(self, obj, c, piso, codigo="", letra="?"):
        x, y = c * T + 16, piso * T
        self.inst.append((obj, x, y, 1, 1, codigo))
        self.extra.append((letra, x, y))

    def jugador(self, c, piso): self._pon("obj_jugador", c, piso, letra="P")
    def enemigo(self, tipo, c, piso): self._pon(ENEMIGOS[tipo], c, piso, letra=tipo)
    def checkpoint(self, c, piso):
        # "orden" = orden en el recorrido (los niveles no siempre avanzan hacia la derecha)
        self.n_cp = getattr(self, "n_cp", 0) + 1
        self._pon("obj_checkpoint", c, piso, "orden = %d;\n" % self.n_cp, "C")

    def minijefe(self, c, piso, vida):
        self._pon("obj_enemigo_boss", c, piso, "vida_maxima = %d;\nvida = vida_maxima;\n" % vida, "MJ")

    def torre(self, c, piso, alto=10):
        # Torre de vigilancia: centinela arriba (alto bloques sobre el suelo) en una plataforma de 3; la
        # estructura de la torre es decorativa (no choca), así que no tapa el camino.
        rp = piso - alto
        self.solido(c - 1, c + 1, rp, rp)
        self.enemigo("T", c, rp)
        self.inst.append(("obj_torre_deco", c * T + 16, piso * T, 1, 1, "alto = %d;\n" % ((piso - rp - 1) * T)))

    def nicho(self, c0, c1, piso):
        # Atalaya excavada en la pared de un pozo, con una centinela
        self.hueco(c0, c1, piso - 3, piso - 1)
        self.enemigo("T", (c0 + c1) // 2, piso)
    def boton(self, c, piso, canal): self._pon("obj_boton", c, piso, "canal = %d;\n" % canal, "B%d" % canal)
    def cierre(self, c, piso, canal_cierre, canal_abrir):
        # Compuerta abierta que se cierra de golpe al entrar a una arena (canal_cierre) y se abre con canal_abrir
        self._pon("obj_puerta_cierre", c, piso, "canal_cierre = %d;\ncanal_abrir = %d;\n" % (canal_cierre, canal_abrir), "X")
    def cerradura(self, c, piso, canal, requiere=-1):
        # Puerta con cerradura: se abre con una llave (obj_llave); "requiere" = canal que debe estar activo antes
        self._pon("obj_puerta_llave", c, piso, "canal = %d;\nrequiere = %d;\n" % (canal, requiere), "K")
    def puerta(self, c, piso, canal): self._pon("obj_puerta", c, piso, "canal = %d;\n" % canal, "D%d" % canal)
    def meta(self, c, piso, siguiente="-1"): self._pon("obj_meta", c, piso, "siguiente = %s;\n" % siguiente, "E")
    def jefe(self, c, piso, siguiente="-1"): self._pon("obj_jefe_demonio", c, piso, "siguiente = %s;\n" % siguiente, "J")

    def grua(self, c, fila_riel, recorrido_cols, largo, canal, largo_final=-1, velocidad=2, retraso=0, ciclo=False):
        x, y = c * T + 16, fila_riel * T + 16
        cod = ("canal = %d;\nrecorrido = %d;\nlargo = %d;\nlargo_final = %d;\nvelocidad = %s;\nretraso = %d;\nciclo = %s;\n"
               % (canal, recorrido_cols * T, largo, largo_final, velocidad, retraso, "true" if ciclo else "false"))
        self.inst.append(("obj_grua", x, y, 1, 1, cod))
        self.extra.append(("G%d" % canal, x, y, recorrido_cols * T, largo, largo_final))

    # Sólidos -> rectángulos (tramos por fila, unidos hacia abajo si son iguales)
    def rectangulos(self):
        usados = [[False] * self.cols for _ in range(self.filas)]
        rects = []
        for r in range(self.filas):
            c = 0
            while c < self.cols:
                if self.g[r][c] == "#" and not usados[r][c]:
                    c1 = c
                    while c1 + 1 < self.cols and self.g[r][c1 + 1] == "#" and not usados[r][c1 + 1]:
                        c1 += 1
                    r1 = r
                    while r1 + 1 < self.filas and all(self.g[r1 + 1][k] == "#" and not usados[r1 + 1][k] for k in range(c, c1 + 1)):
                        r1 += 1
                    for rr in range(r, r1 + 1):
                        for k in range(c, c1 + 1):
                            usados[rr][k] = True
                    rects.append((c, r, c1 - c + 1, r1 - r + 1))
                    c = c1 + 1
                else:
                    c += 1
        return rects

    def tramos_pinchos(self):
        out = []
        for r in range(self.filas):
            c = 0
            while c < self.cols:
                if self.g[r][c] == "^":
                    c1 = c
                    while c1 + 1 < self.cols and self.g[r][c1 + 1] == "^":
                        c1 += 1
                    out.append((c, r, c1 - c + 1))
                    c = c1 + 1
                else:
                    c += 1
        return out


# ======================================================================================
# NIVEL 1 — Distrito de Neón (~2-3 min): combate básico, foso de pinchos, centinelas,
# GRÚA sobre un mar de pinchos (botón -> la plataforma se acerca -> gancho), saltos sobre
# pinchos y compuerta que se abre con un botón en lo alto.
# ======================================================================================
def nivel_1():
    L = Nivel("Nivel_1", 250, titulo="Nivel 1: Distrito de Neon",
              subtitulo="Pulsa el boton para mover la grua y cruza el mar de pinchos con el gancho")
    L.solido(0, 1, 0, 29); L.solido(248, 249, 0, 29)                 # paredes de los extremos

    # A. Inicio y primeros enemigos
    L.solido(2, 43, 25, 29)
    L.jugador(5, 25)
    L.solido(14, 17, 22, 24)
    L.solido(24, 27, 23, 24)
    L.enemigo("L", 32, 25); L.enemigo("L", 39, 25)

    # B. Foso con pinchos y centinela en lo alto
    L.solido(44, 51, 28, 29); L.pinchos(44, 51, 27)
    L.solido(52, 99, 25, 29)
    L.solido(56, 59, 21, 21)
    L.torre(67, 25)
    L.enemigo("L", 61, 25); L.enemigo("L", 75, 25)
    L.checkpoint(80, 25)

    # C. Mar de pinchos con grúa. Botón abajo; torre antes del mar; techo para el riel;
    #    columna colgante a mitad del mar como segundo punto de gancho.
    L.boton(84, 25, 1)
    L.solido(88, 91, 22, 24)
    L.solido(92, 99, 19, 24)
    L.solido(100, 131, 28, 29); L.pinchos(100, 131, 27)
    L.solido(94, 136, 0, 1)
    L.solido(120, 121, 2, 9)
    L.grua(96, 2, 14, 224, canal=1)                                   # col 96 -> col 110
    L.solido(132, 139, 21, 29)
    L.checkpoint(136, 21)

    # D. Arena
    L.solido(140, 185, 25, 29)
    L.solido(150, 153, 21, 21)
    L.torre(162, 25)
    L.enemigo("L", 147, 25); L.enemigo("M", 156, 25); L.enemigo("L", 166, 25); L.enemigo("L", 176, 25)
    L.checkpoint(183, 25)

    # E. Plataformas sobre suelo de pinchos
    L.solido(186, 247, 25, 29); L.pinchos(186, 214, 24)
    L.solido(188, 191, 21, 21)
    L.solido(196, 199, 19, 19); L.enemigo("L", 197, 19)
    L.solido(204, 207, 21, 21)
    L.solido(211, 213, 19, 19)

    # F. Compuerta: el botón está en una repisa alta; muro desde el techo hasta la puerta
    L.solido(216, 218, 21, 21)
    L.solido(220, 224, 17, 17); L.boton(222, 17, 2)
    L.solido(228, 228, 0, 20); L.puerta(228, 25, 2)
    L.enemigo("L", 234, 25); L.torre(240, 25)
    L.meta(244, 25, "Room_Boss")
    return L


# ======================================================================================
# NIVEL 2 — Fundición (~3-4 min): pesados y medianos, fosos con centinelas, ASCENSOR de grúa
# para subir un muro, DOBLE GRÚA sobre un mar de pinchos (la segunda se activa desde una
# isla a la que solo se llega con la primera) y compuerta final. Sale a Room_Boss.
# ======================================================================================
def nivel_2():
    L = Nivel("Nivel_2", 280, titulo="Nivel 2: Fundicion",
              subtitulo="Ascensor, doble grua y compuerta. Al final te espera el jefe",
              cielo=((22, 8, 10), (70, 26, 14)))
    L.solido(0, 1, 0, 29); L.solido(278, 279, 0, 29)

    # A. Inicio con un pesado
    L.solido(2, 47, 25, 29)
    L.jugador(5, 25)
    L.solido(16, 19, 22, 24)
    L.enemigo("L", 26, 25); L.enemigo("H", 36, 25)

    # B. Tres fosos con centinelas
    L.solido(48, 54, 28, 29); L.pinchos(48, 54, 27)
    L.solido(55, 62, 25, 29)
    L.torre(58, 25)
    L.solido(63, 70, 28, 29); L.pinchos(63, 70, 27)
    L.solido(66, 67, 22, 22)
    L.solido(71, 78, 25, 29); L.enemigo("L", 75, 25)
    L.solido(79, 86, 28, 29); L.pinchos(79, 86, 27)
    L.torre(83, 27, alto=12)
    L.solido(87, 103, 25, 29)
    L.checkpoint(90, 25)

    # C. Ascensor: la plataforma espera en el suelo; el botón la sube (con 1 s de margen
    #    para subirse) hasta la altura del muro.
    L.boton(94, 25, 1)
    L.grua(98, 2, 0, 700, canal=1, largo_final=168, velocidad=2, retraso=60, ciclo=True)
    L.solido(104, 108, 8, 29)

    # D. Arena de la fundición
    L.solido(109, 149, 25, 29)
    L.torre(126, 25)
    L.enemigo("M", 118, 25); L.enemigo("H", 132, 25); L.enemigo("M", 140, 25)
    L.solido(147, 149, 22, 24)
    L.solido(150, 155, 20, 29)
    L.checkpoint(151, 20)

    # E. Doble grúa sobre el mar de pinchos, con una isla en medio
    L.boton(153, 20, 2)
    L.solido(156, 203, 28, 29); L.pinchos(156, 203, 27)
    L.solido(150, 210, 0, 1)
    L.grua(157, 2, 10, 256, canal=2)                                  # col 157 -> col 167
    L.solido(176, 179, 20, 27)
    L.boton(178, 20, 3)
    L.grua(200, 2, -10, 256, canal=3)                                 # col 200 -> col 190
    L.solido(204, 215, 20, 29)
    L.checkpoint(210, 20)

    # F. Plataformas sobre pinchos hasta el botón de la compuerta
    L.solido(216, 277, 25, 29); L.pinchos(222, 245, 24)
    L.solido(224, 227, 21, 21)
    L.solido(231, 234, 18, 18)
    L.solido(238, 242, 15, 15); L.boton(240, 15, 4)
    L.enemigo("H", 252, 25); L.enemigo("L", 257, 25)
    L.solido(262, 262, 0, 20); L.puerta(262, 25, 4)
    L.enemigo("L", 268, 25); L.torre(271, 25)
    L.meta(274, 25, "Nivel_3")
    return L


# ======================================================================================
# NIVEL 3 — Ciudadela Abismal (estilo metroidvania, ~8-10 min). Todo es roca y se excavan los pasillos.
# Siempre se avanza (nunca hay que volver a por un botón):
#   A salón de entrada -> B pozo 1 hacia ARRIBA -> C galería alta hacia la derecha (foso con bloque colgante,
#   grúa sobre pinchos) -> D pozo 2 hacia ABAJO -> E corredor medio hacia la IZQUIERDA -> ascensor que BAJA
#   -> F corredor inferior hacia la DERECHA -> cámara del GUARDIÁN (minijefe: el jefe 1 con 40 % de vida): al
#   entrar se cierra la puerta; al vencerlo se abre la salida y suelta la llave de la puerta final -> pozo 3 hacia ARRIBA -> ARENA final (la salida
#   se abre con la llave del guardián, tras vencer a todos). Las centinelas están en torres o atalayas altas, nunca en el camino.
# ======================================================================================
def nivel_3():
    L = Nivel("Nivel_3", 230, filas=100, titulo="Nivel 3: Ciudadela Abismal",
              subtitulo="Sube, baja y abrete paso. La salida esta custodiada",
              cielo=((6, 10, 20), (20, 40, 60)))
    L.solido(0, 229, 0, 99)                                               # todo es roca

    # A. Salón de entrada
    L.hueco(2, 44, 82, 94)
    L.jugador(5, 95)
    L.solido(14, 16, 92, 94)
    L.torre(32, 95)
    L.enemigo("L", 21, 95); L.enemigo("L", 26, 95)
    L.checkpoint(41, 95)

    # B. Pozo 1 hacia arriba (centinelas en atalayas de las paredes)
    L.hueco(45, 64, 10, 94)
    for r, a, b in [(91, 50, 55), (87, 57, 62), (83, 50, 55), (79, 57, 62), (75, 47, 52), (71, 54, 59), (67, 59, 64),
                    (63, 50, 55), (59, 45, 49), (55, 52, 57), (51, 58, 64), (47, 50, 55), (43, 45, 50), (39, 52, 57),
                    (35, 58, 64), (31, 51, 56), (27, 45, 50), (23, 53, 58), (19, 59, 64)]:
        L.solido(a, b, r, r)
    L.nicho(42, 44, 70); L.nicho(65, 67, 58); L.nicho(42, 44, 34)
    L.enemigo("L", 56, 71); L.enemigo("L", 53, 47); L.enemigo("L", 55, 23)
    L.checkpoint(52, 63)

    # C. Galería alta hacia la derecha
    L.hueco(65, 140, 6, 18)
    L.checkpoint(68, 19)
    L.hueco(78, 90, 19, 21); L.pinchos(78, 90, 22)                        # foso 1
    L.solido(82, 86, 6, 9)                                                # bloque colgante (gancho)
    L.torre(96, 19, alto=9)
    L.enemigo("M", 95, 19); L.enemigo("L", 100, 19); L.enemigo("H", 107, 19)
    L.boton(110, 19, 1)
    L.hueco(115, 133, 19, 21); L.pinchos(115, 133, 22)                    # foso 2 (con grúa)
    L.grua(104, 6, 18, 160, canal=1)                                      # col 104 -> col 122
    L.checkpoint(137, 19)

    # D. Pozo 2 hacia abajo (hasta la fila 46)
    L.hueco(141, 160, 6, 46)
    for r, a, b in [(24, 141, 146), (30, 152, 159), (36, 143, 149), (42, 150, 156)]:
        L.solido(a, b, r, r)
    L.pinchos(153, 159, 46)
    L.nicho(138, 140, 33)
    L.enemigo("L", 155, 30); L.enemigo("L", 153, 42)
    L.checkpoint(144, 47)

    # E. Corredor medio hacia la izquierda, con una torre en un hueco alto
    L.hueco(81, 140, 38, 46)
    L.pinchos(116, 118, 46)
    L.hueco(100, 112, 30, 37); L.torre(106, 47)
    L.enemigo("H", 128, 47); L.enemigo("M", 113, 47); L.enemigo("L", 102, 47); L.enemigo("L", 94, 47)
    L.checkpoint(86, 47)
    #    Ascensor que baja: el botón está en la repisa, junto a la plataforma (1,5 s para subirse)
    L.hueco(70, 80, 38, 70)
    L.solido(77, 80, 47, 47); L.boton(79, 47, 4)
    L.grua(75, 38, 0, 47 * T - (38 * T + 16), canal=4, largo_final=71 * T - 20 - (38 * T + 16),
           velocidad=3, retraso=90, ciclo=True)

    # F. Corredor inferior hacia la derecha
    L.hueco(70, 164, 62, 70)
    L.checkpoint(84, 71)
    L.pinchos(97, 99, 70); L.pinchos(126, 129, 70)
    L.hueco(104, 110, 58, 61); L.torre(107, 71)
    L.enemigo("L", 92, 71); L.enemigo("M", 118, 71); L.enemigo("L", 136, 71); L.enemigo("H", 148, 71)
    L.checkpoint(160, 71)

    #    Cámara del guardián: minijefe (jefe 1 con el 40 % de su vida, 200). Al entrar, la compuerta de la entrada
    #    cae (canal 6) y no se puede salir; al vencerlo la salida de la cámara se abre sola (canal 5) y suelta la
#    LLAVE de la puerta final del nivel.
    L.hueco(165, 203, 56, 70)
    L.solido(164, 164, 62, 66); L.cierre(164, 71, canal_cierre=6, canal_abrir=5)
    L.solido(170, 173, 65, 65); L.solido(185, 188, 65, 65)
    L.minijefe(182, 71, 200)
    L.arena(166, 193, 56, 70, canal=5, mensaje="Vence al guardian", jefe="GUARDIAN", cierre=6, premio="obj_llave")
    L.solido(194, 194, 56, 66); L.puerta(194, 71, 5)
    L.hueco(195, 204, 62, 70)
    L.checkpoint(203, 71)

    # G. Pozo 3 hacia arriba (atalayas en las paredes)
    L.hueco(205, 220, 36, 70); L.pinchos(205, 210, 70)
    for r, a, b in [(67, 214, 219), (63, 206, 211), (59, 214, 219), (55, 206, 211), (51, 213, 219),
                    (47, 205, 210), (43, 213, 219), (39, 206, 211)]:
        L.solido(a, b, r, r)
    L.nicho(221, 223, 54); L.nicho(202, 204, 44)
    L.enemigo("L", 207, 47)
    L.checkpoint(217, 51)

    # ARENA FINAL: se entra por un hueco en el suelo (derecha); la salida está a la izquierda tras una compuerta
    L.hueco(162, 225, 22, 34); L.hueco(205, 212, 35, 35)
    L.solido(166, 166, 22, 30); L.cerradura(166, 35, 7, requiere=3)      # salida: llave del guardián
    L.meta(163, 35, "Jefe_Demonio")
    L.torre(176, 35); L.torre(190, 35); L.torre(218, 35)
    L.enemigo("H", 172, 35); L.enemigo("H", 196, 35)
    L.enemigo("M", 180, 35); L.enemigo("M", 192, 35); L.enemigo("M", 222, 35)
    L.enemigo("L", 184, 35); L.enemigo("L", 200, 35); L.enemigo("L", 215, 35); L.enemigo("L", 224, 35)
    L.arena(167, 225, 22, 34, canal=3, mensaje="Acaba con todos para usar la llave en la salida")
    return L


# ======================================================================================
# JEFE FINAL: arena de Azraek, el Desollador. Plataformas para pelear en el aire. Al vencerlo aparece
# el portal (vuelve al Nivel 1).
# ======================================================================================
def jefe_demonio():
    L = Nivel("Jefe_Demonio", 60, filas=24, titulo="Jefe: Azraek, el Desollador",
              subtitulo="Rapido y escurridizo. Mata a sus diablitos para recuperar vida",
              cielo=((18, 4, 8), (80, 10, 20)))
    L.solido(0, 1, 0, 23); L.solido(58, 59, 0, 23)
    L.solido(2, 57, 21, 23)
    L.solido(9, 15, 16, 16)
    L.solido(44, 50, 16, 16)
    L.solido(26, 33, 12, 12)
    L.jugador(6, 21)
    L.jefe(46, 21, "Nivel_1")
    return L


# ======================================================================================
def nombre_inst(nivel, i, obj):
    return "inst_" + hashlib.md5(("%s-%d-%s" % (nivel, i, obj)).encode()).hexdigest()[:8].upper()


def inst_json(nombre, obj, x, y, sx, sy, codigo):
    return ('        {"$GMRInstance":"v4","%%Name":"%s","colour":4294967295,"frozen":false,"hasCreationCode":%s,"ignore":false,'
            '"imageIndex":0,"imageSpeed":1.0,"inheritCode":false,"inheritedItemId":null,"inheritItemSettings":false,"isDnd":false,'
            '"name":"%s","objectId":{"name":"%s","path":"objects/%s/%s.yy",},"properties":[],"resourceType":"GMRInstance",'
            '"resourceVersion":"2.0","rotation":0.0,"scaleX":%.1f,"scaleY":%.1f,"x":%.1f,"y":%.1f,},\n'
            % (nombre, "true" if codigo else "false", nombre, obj, obj, obj, sx, sy, x, y))


def room_yy(L, insts):
    W, H = L.cols * T, L.filas * T
    orden = "".join('    {"name":"%s","path":"rooms/%s/%s.yy",},\n' % (n, L.nombre, L.nombre) for n, *_ in insts)
    lista = "".join(inst_json(n, o, x, y, sx, sy, cod) for n, o, x, y, sx, sy, cod in insts)
    # Vista 0 activa de 1366x768 (la resolución del juego); las otras 7 apagadas
    v = ('    {"hborder":32,"hport":768,"hspeed":-1,"hview":768,"inherit":false,"objectId":null,"vborder":32,"visible":%s,'
         '"vspeed":-1,"wport":1366,"wview":1366,"xport":0,"xview":0,"yport":0,"yview":0,},\n')
    vista = (v % "true") + (v % "false") * 7
    return ('{\n  "$GMRoom":"v1",\n  "%%Name":"%(n)s",\n  "creationCodeFile":"",\n  "inheritCode":false,\n  "inheritCreationOrder":false,\n'
            '  "inheritLayers":false,\n  "instanceCreationOrder":[\n%(orden)s  ],\n  "isDnd":false,\n  "layers":[\n'
            '    {"$GMRInstanceLayer":"","%%Name":"Instances","depth":0,"effectEnabled":true,"effectType":null,"gridX":32,"gridY":32,'
            '"hierarchyFrozen":false,"inheritLayerDepth":false,"inheritLayerSettings":false,"inheritSubLayers":true,"inheritVisibility":true,'
            '"instances":[\n%(lista)s      ],"layers":[],"name":"Instances","properties":[],"resourceType":"GMRInstanceLayer","resourceVersion":"2.0",'
            '"userdefinedDepth":false,"visible":true,},\n'
            '    {"$GMRBackgroundLayer":"","%%Name":"Background","animationFPS":15.0,"animationSpeedType":0,"colour":4280879626,"depth":100,'
            '"effectEnabled":true,"effectType":null,"gridX":32,"gridY":32,"hierarchyFrozen":false,"hspeed":0.0,"htiled":false,'
            '"inheritLayerDepth":false,"inheritLayerSettings":false,"inheritSubLayers":true,"inheritVisibility":true,"layers":[],'
            '"name":"Background","properties":[],"resourceType":"GMRBackgroundLayer","resourceVersion":"2.0","spriteId":null,"stretch":false,'
            '"userdefinedAnimFPS":false,"userdefinedDepth":false,"visible":true,"vspeed":0.0,"vtiled":false,"x":0,"y":0,},\n  ],\n'
            '  "name":"%(n)s",\n  "parent":{\n    "name":"Blank Pixel Game",\n    "path":"Blank Pixel Game.yyp",\n  },\n  "parentRoom":null,\n'
            '  "physicsSettings":{\n    "inheritPhysicsSettings":false,\n    "PhysicsWorld":false,\n    "PhysicsWorldGravityX":0.0,\n'
            '    "PhysicsWorldGravityY":10.0,\n    "PhysicsWorldPixToMetres":0.1,\n  },\n  "resourceType":"GMRoom",\n  "resourceVersion":"2.0",\n'
            '  "roomSettings":{\n    "Height":%(h)d,\n    "inheritRoomSettings":false,\n    "persistent":false,\n    "Width":%(w)d,\n  },\n'
            '  "sequenceId":null,\n  "views":[\n%(vista)s  ],\n  "viewSettings":{\n    "clearDisplayBuffer":true,\n    "clearViewBackground":false,\n'
            '    "enableViews":true,\n    "inheritViewSettings":false,\n  },\n  "volume":1.0,\n}'
            ) % dict(n=L.nombre, orden=orden, lista=lista, vista=vista, w=W, h=H)


def generar(L):
    d = os.path.join(P, "rooms", L.nombre)
    os.makedirs(d, exist_ok=True)
    for f in os.listdir(d):                               # códigos de creación de una versión anterior
        if f.startswith("InstanceCreationCode_") or f.endswith(".yy"):
            os.remove(os.path.join(d, f))

    cielo = "cielo_arriba = make_color_rgb(%d, %d, %d);\ncielo_abajo = make_color_rgb(%d, %d, %d);\n" % (L.cielo[0] + L.cielo[1])
    base = [("obj_controladores", 32, 32, 1, 1, ""), ("obj_mecanicas_jugador", 64, 32, 1, 1, ""),
            ("obj_mec_golpe", 96, 32, 1, 1, ""),
            ("obj_nivel", 128, 32, 1, 1, 'nombre = "%s";\nsubtitulo = "%s";\n%s' % (L.titulo, L.subtitulo, cielo))]
    todos = base + [i for i in L.inst if i[0] == "obj_jugador"]
    for c, r, w, h in L.rectangulos():
        todos.append(("obj_solid", c * T, r * T, w, h, ""))
    for c, r, n in L.tramos_pinchos():
        todos.append(("obj_pinchos", c * T + n * 16, (r + 1) * T, n, 1, ""))
    todos += [i for i in L.inst if i[0] != "obj_jugador"]

    insts = []
    for i, (o, x, y, sx, sy, cod) in enumerate(todos):
        n = nombre_inst(L.nombre, i, o)
        insts.append((n, o, x, y, sx, sy, cod))
        if cod:
            open(os.path.join(d, "InstanceCreationCode_%s.gml" % n), "w", encoding="utf-8", newline="\n").write(cod)
    open(os.path.join(d, L.nombre + ".yy"), "w", encoding="utf-8", newline="\n").write(room_yy(L, insts))
    return len(insts)


def registrar(nombres):
    s = open(YYP, encoding="utf-8").read()
    for n in nombres:
        ruta = '"path":"rooms/%s/%s.yy"' % (n, n)
        if ruta not in s:
            s = s.replace('    {"id":{"name":"Room_Boss"', '    {"id":{"name":"%s","path":"rooms/%s/%s.yy",},},\n    {"id":{"name":"Room_Boss"' % (n, n, n), 1)
        nodo = '{"roomId":{"name":"%s",' % n
        if nodo not in s:
            i = s.index('"RoomOrderNodes":[')
            j = s.index("  ],", i)
            s = s[:j] + '    {"roomId":{"name":"%s","path":"rooms/%s/%s.yy",},},\n' % (n, n, n) + s[j:]
    open(YYP, "w", encoding="utf-8").write(s)


def preview(L):
    from PIL import Image, ImageDraw
    os.makedirs(PREV, exist_ok=True)
    S = 4
    im = Image.new("RGB", (L.cols * S, L.filas * S), (20, 18, 38))
    d = ImageDraw.Draw(im)
    for r in range(L.filas):
        for c in range(L.cols):
            if L.g[r][c] == "#": d.rectangle([c * S, r * S, c * S + S - 1, r * S + S - 1], fill=(70, 76, 100))
            elif L.g[r][c] == "^": d.rectangle([c * S, r * S + S // 2, c * S + S - 1, r * S + S - 1], fill=(230, 40, 50))
    col = {"J": (255, 0, 0), "P": (0, 255, 120), "L": (255, 200, 0), "M": (255, 130, 0), "H": (255, 60, 0), "T": (255, 0, 200),
           "C": (0, 230, 255), "E": (255, 255, 255)}
    for e in L.extra:
        k, x, y = e[0], e[1] / T * S, e[2] / T * S
        if k.startswith("G"):
            rec, largo, lf = e[3] / T * S, e[4] / T * S, (e[5] if e[5] >= 0 else e[4]) / T * S
            d.line([x, y, x + rec, y], fill=(250, 200, 40))
            d.rectangle([x - 6, y + largo, x + 6, y + largo + 2], fill=(150, 150, 150))
            d.rectangle([x + rec - 6, y + lf, x + rec + 6, y + lf + 2], fill=(250, 200, 40))
        elif k.startswith("B") or k.startswith("D"):
            d.rectangle([x - 3, y - (16 if k[0] == "D" else 4), x + 3, y], fill=(60, 230, 120) if k[0] == "B" else (230, 40, 160))
        else:
            d.rectangle([x - 2, y - 6, x + 2, y], fill=col.get(k, (255, 255, 255)))
    im = im.resize((im.width * 2 // 2, im.height * 2 // 2))
    im.save(os.path.join(PREV, "preview_%s.png" % L.nombre))


if __name__ == "__main__":
    niveles = [nivel_1(), jefe_demonio(), nivel_2(), nivel_3()]
    for L in niveles:
        n = generar(L)
        preview(L)
        print("%s: %dx%d px, %d instancias" % (L.nombre, L.cols * T, L.filas * T, n))
    registrar([L.nombre for L in niveles])
    print("listo")
