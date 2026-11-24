# Crea (o actualiza) los objetos y el script de elementos de nivel en el proyecto GameMaker.
# Correr desde Blank Pixel Game/arte_generado con GameMaker CERRADO:  python3 crear_objetos_nivel.py
import os, re

P = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
YYP = os.path.join(P, "Blank Pixel Game.yyp")

EV = {"Create_0": (0, 0), "Step_0": (0, 3), "Step_1": (1, 3), "Step_2": (2, 3),
      "Draw_0": (0, 8), "Draw_64": (64, 8), "Draw_72": (72, 8)}


def obj_yy(nombre, eventos, sprite=None, padre=None):
    ev = "".join('    {"$GMEvent":"v1","%%Name":"","collisionObjectId":null,"eventNum":%d,"eventType":%d,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},\n' % EV[e] for e in eventos)
    spr = '{\n    "name":"%s",\n    "path":"sprites/%s/%s.yy",\n  }' % (sprite, sprite, sprite) if sprite else "null"
    par = '{\n    "name":"%s",\n    "path":"objects/%s/%s.yy",\n  }' % (padre, padre, padre) if padre else "null"
    return ('{\n  "$GMObject":"",\n  "%%Name":"%s",\n  "eventList":[\n%s  ],\n  "managed":true,\n  "name":"%s",\n  "overriddenProperties":[],\n'
            '  "parent":{\n    "name":"Blank Pixel Game",\n    "path":"Blank Pixel Game.yyp",\n  },\n  "parentObjectId":%s,\n  "persistent":false,\n'
            '  "physicsAngularDamping":0.1,\n  "physicsDensity":0.5,\n  "physicsFriction":0.2,\n  "physicsGroup":1,\n  "physicsKinematic":false,\n'
            '  "physicsLinearDamping":0.1,\n  "physicsObject":false,\n  "physicsRestitution":0.1,\n  "physicsSensor":false,\n  "physicsShape":1,\n'
            '  "physicsShapePoints":[],\n  "physicsStartAwake":true,\n  "properties":[],\n  "resourceType":"GMObject",\n  "resourceVersion":"2.0",\n'
            '  "solid":false,\n  "spriteId":%s,\n  "spriteMaskId":null,\n  "visible":true,\n}') % (nombre, ev, nombre, par, spr)


SCRIPT = r'''// ==============================
// ELEMENTOS DE NIVEL (propios): canales, checkpoints y reaparición.
// Un botón activa un canal (número). Las grúas y compuertas con ese canal reaccionan.
// El canal y los demás parámetros de cada instancia se ponen en su código de creación
// (lo escribe arte_generado/generar_niveles.py).
// ==============================

function nivel_canal_activo(_c)
{
    if (!variable_global_exists("nivel_canales")) return false;
    return _c >= 0 && _c < array_length(global.nivel_canales) && global.nivel_canales[_c];
}

function nivel_activar_canal(_c)
{
    if (!variable_global_exists("nivel_canales")) global.nivel_canales = [];
    while (array_length(global.nivel_canales) <= _c) array_push(global.nivel_canales, false);
    global.nivel_canales[_c] = true;
}

function nivel_jugador()
{
    return instance_exists(obj_jugador) ? instance_find(obj_jugador, 0) : noone;
}

function nivel_invulnerable()
{
    return variable_global_exists("nivel_invulnerable") && global.nivel_invulnerable > 0;
}

// Punto de reaparición: el último checkpoint de esta room o, si no hay, el inicio del nivel
function nivel_punto_reaparicion()
{
    if (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room == room)
        return [global.nivel_cp.x, global.nivel_cp.y];
    var _r = undefined;
    with (obj_nivel) _r = [inicio_x, inicio_y];
    return _r;
}

// Lleva al jugador a (_x, _y) cancelando lo que estuviera haciendo (gancho, excavación...)
function nivel_mover_jugador(_x, _y)
{
    var _j = nivel_jugador();
    if (_j == noone) return;
    with (obj_mecanicas_jugador)
    {
        if (mec_gancho_activo()) mec_gancho_soltar();
        gancho_inercia_x = 0;
        if (ud_bajo_tierra) mec_underdog_salir(false);
        if (ud_accion != UdAccion.ARRASTRE) ud_accion = UdAccion.NINGUNA;
        dash_timer = 0;
        x_inicio = _x;
        y_inicio = _y;
    }
    _j.x = _x;
    _j.y = _y;
    _j.hsp = 0;
    _j.vsp = 0;
    with (obj_camara) saltar_a(_x, _y);
}

// Caída al vacío o pinchos: vuelve al punto de reaparición con daño e invulnerabilidad breve
function nivel_reaparecer(_danio)
{
    var _p = nivel_punto_reaparicion();
    var _j = nivel_jugador();
    if (_j == noone || is_undefined(_p)) return;
    global.nivel_invulnerable = 60;
    global.nivel_flash = 14;
    nivel_mover_jugador(_p[0], _p[1]);
    if (_danio > 0 && instance_exists(_j)) _j.recibir_impacto(_danio, 0, 0, 0);
}

// Texto pequeño con contorno (avisos de los elementos de nivel)
function nivel_texto(_x, _y, _txt, _col, _alpha)
{
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_alpha(_alpha);
    draw_set_color(c_black);
    draw_text(_x + 1, _y + 1, _txt);
    draw_set_color(_col);
    draw_text(_x, _y, _txt);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
'''

OBJ = {}

# ---------------- obj_nivel: controlador del nivel, fondo, terreno, HUD ----------------
OBJ["obj_nivel"] = (None, None, {
"Create_0": r'''// Controlador del nivel (uno por room de nivel). Lo pone generar_niveles.py.
// Código de creación: nombre, subtitulo, cielo_arriba / cielo_abajo (colores).
nombre = "Nivel";
subtitulo = "";
cielo_arriba = make_color_rgb(10, 10, 26);
cielo_abajo = make_color_rgb(46, 16, 58);
neon_a = make_color_rgb(0, 230, 255);
neon_b = make_color_rgb(230, 40, 160);

inicio_x = 0;
inicio_y = 0;
colocado = false;
t_inicio = current_time;
t_final = -1;
banner = 240;

global.nivel_canales = [];
global.nivel_invulnerable = 0;
global.nivel_flash = 0;
if (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room != room) global.nivel_cp = undefined;

// Fondo: dos capas de edificios con parallax (siempre iguales para la misma room)
random_set_seed(room_width * 7 + room_height);
fondo_lejos = [];
fondo_cerca = [];
var _x = -200;
while (_x < room_width * 0.3 + 1600)
{
    var _w = irandom_range(70, 150);
    array_push(fondo_lejos, { x: _x, w: _w, h: irandom_range(220, 460), s: irandom(99) });
    _x += _w + irandom_range(6, 26);
}
_x = -200;
while (_x < room_width * 0.55 + 1600)
{
    var _w2 = irandom_range(50, 120);
    array_push(fondo_cerca, { x: _x, w: _w2, h: irandom_range(120, 320), s: irandom(99) });
    _x += _w2 + irandom_range(20, 70);
}
randomize();
''',
"Step_0": r'''global.nivel_invulnerable = max(0, global.nivel_invulnerable - 1);
global.nivel_flash = max(0, global.nivel_flash - 1);
banner = max(0, banner - 1);

var _j = nivel_jugador();
if (!colocado)
{
    // El terreno se dibuja con tiles propios: los obj_solid del nivel se ocultan
    with (obj_solid) if (object_index == obj_solid) visible = false;
    if (_j != noone)
    {
        inicio_x = _j.x;
        inicio_y = _j.y;
        var _p = nivel_punto_reaparicion();
        nivel_mover_jugador(_p[0], _p[1]);
        colocado = true;
    }
}

// Caída al vacío
if (_j != noone && _j.y > room_height + 96) nivel_reaparecer(15);
''',
"Draw_72": r'''// Draw Begin: corre antes de todos los Draw, así el fondo y el terreno quedan detrás de todo
var _cam = view_camera[0];
var _cx = 0, _cy = 0, _vw = room_width, _vh = room_height;
if (_cam != -1)
{
    _cx = camera_get_view_x(_cam);
    _cy = camera_get_view_y(_cam);
    _vw = camera_get_view_width(_cam);
    _vh = camera_get_view_height(_cam);
}

// Cielo
draw_rectangle_colour(_cx, _cy, _cx + _vw, _cy + _vh, cielo_arriba, cielo_arriba, cielo_abajo, cielo_abajo, false);

// Edificios lejanos (parallax 0.25) y cercanos (0.5), con ventanas de neón
var _capas = [[fondo_lejos, 0.25, make_color_rgb(22, 20, 42), neon_b, 0.35, 0.75],
              [fondo_cerca, 0.5, make_color_rgb(30, 26, 52), neon_a, 0.45, 1.0]];
for (var c = 0; c < 2; c++)
{
    var _lista = _capas[c][0];
    var _f = _capas[c][1];
    var _base = _cy + _vh - (room_height - (_cy + _vh)) * _f * 0.3;
    for (var i = 0; i < array_length(_lista); i++)
    {
        var _b = _lista[i];
        var _bx = _cx - _cx * _f + _b.x;
        if (_bx + _b.w < _cx || _bx > _cx + _vw) continue;
        var _top = _base - _b.h * _capas[c][5];
        draw_set_color(_capas[c][2]);
        draw_rectangle(_bx, _top, _bx + _b.w, _base + 40, false);
        draw_set_color(_capas[c][3]);
        draw_set_alpha(_capas[c][4]);
        for (var wy = _top + 10; wy < _base - 6; wy += 18)
            for (var wx = _bx + 6; wx < _bx + _b.w - 8; wx += 14)
                if (((wx - _bx) * 7 + (wy - _top) * 3 + _b.s) mod 11 == 0) draw_rectangle(wx, wy, wx + 5, wy + 3, false);
        draw_set_alpha(1);
    }
}

// Terreno: tiles sobre los obj_solid (superficie arriba si no hay sólido encima)
var _x1 = _cx - 32, _x2 = _cx + _vw + 32, _y1 = _cy - 32, _y2 = _cy + _vh + 32;
with (obj_solid)
{
    if (object_index != obj_solid) continue;
    if (bbox_right < _x1 || bbox_left > _x2 || bbox_bottom < _y1 || bbox_top > _y2) continue;
    var _c0 = max(floor(bbox_left / 32), floor(_x1 / 32));
    var _c1 = min(floor(bbox_right / 32), floor(_x2 / 32));
    var _r0 = max(floor(bbox_top / 32), floor(_y1 / 32));
    var _r1 = min(floor(bbox_bottom / 32), floor(_y2 / 32));
    var _top_fila = floor(bbox_top / 32);
    for (var cc = _c0; cc <= _c1; cc++)
    {
        for (var rr = _r0; rr <= _r1; rr++)
        {
            var _t;
            if (rr == _top_fila && collision_point(cc * 32 + 16, rr * 32 - 16, obj_solid, false, false) == noone) _t = 0;
            else _t = ((cc * 7 + rr * 13) mod 6 == 0) ? 2 : 1;
            draw_sprite(spr_nivel_tile, _t, cc * 32 + 16, rr * 32 + 32);
        }
    }
}
''',
"Draw_64": r'''var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

// Destello al reaparecer
if (global.nivel_flash > 0)
{
    draw_set_color(c_white);
    draw_set_alpha(global.nivel_flash / 14 * 0.5);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
}

// Cronómetro
var _ms = (t_final >= 0) ? t_final : (current_time - t_inicio);
var _s = _ms div 1000;
var _txt = string(_s div 60) + ":" + string_replace_all(string_format(_s mod 60, 2, 0), " ", "0");
draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text(_gw / 2, 16, nombre + "   " + _txt);

// Cartel de inicio
if (banner > 0)
{
    var _a = min(1, banner / 40) * min(1, (240 - banner) / 20);
    draw_set_alpha(_a * 0.6);
    draw_set_color(c_black);
    draw_rectangle(0, _gh * 0.32, _gw, _gh * 0.32 + 84, false);
    draw_set_alpha(_a);
    draw_set_color(neon_a);
    draw_text_transformed(_gw / 2, _gh * 0.32 + 12, string_upper(nombre), 2.5, 2.5, 0);
    draw_set_color(c_ltgray);
    draw_text(_gw / 2, _gh * 0.32 + 58, subtitulo);
    draw_set_alpha(1);
}

// Fin del nivel
if (t_final >= 0)
{
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(0, _gh * 0.4, _gw, _gh * 0.4 + 70, false);
    draw_set_alpha(1);
    draw_set_color(neon_a);
    draw_text_transformed(_gw / 2, _gh * 0.4 + 10, "NIVEL COMPLETADO", 2.5, 2.5, 0);
    draw_set_color(c_white);
    draw_text(_gw / 2, _gh * 0.4 + 48, "Tiempo: " + _txt);
}
draw_set_halign(fa_left);
draw_set_color(c_white);
'''})

# ---------------- obj_pinchos ----------------
OBJ["obj_pinchos"] = ("spr_nivel_pinchos", None, {
"Create_0": r'''// Pinchos: el generador pone una instancia por tramo (image_xscale = número de celdas).
// Al jugador lo devuelven al último checkpoint con daño; a los enemigos lanzados los hieren y rebotan.
danio = 20;
image_speed = 0;
''',
"Step_0": r'''var _j = nivel_jugador();
if (_j != noone && !nivel_invulnerable() && place_meeting(x, y, _j))
{
    with (obj_camara) aplicar_temblor(5, 12);
    nivel_reaparecer(danio);
}

// Enemigos que caen o son lanzados a los pinchos
with (obj_enemigo)
{
    if (!lanzable || !visible) continue;
    if (!variable_instance_exists(id, "nv_pincho_cd")) nv_pincho_cd = 0;
    if (nv_pincho_cd > 0) { nv_pincho_cd--; continue; }
    if (place_meeting(x, y, other))
    {
        nv_pincho_cd = 40;
        recibir_impacto(12, 0, -9, 30);
    }
}
''',
"Draw_0": r'''var _n = max(1, round(image_xscale));
var _x0 = x - _n * 16;
for (var i = 0; i < _n; i++) draw_sprite(sprite_index, 0, _x0 + 16 + i * 32, y);
'''})

# ---------------- obj_boton ----------------
OBJ["obj_boton"] = ("spr_nivel_boton", None, {
"Create_0": r'''// Botón de suelo: se activa al pisarlo o al golpearlo. Activa su canal (una sola vez).
// Código de creación: canal.
canal = 1;
pulsado = false;
brillo = 0;
t = 0;
image_speed = 0;
''',
"Step_0": r'''t++;
brillo = max(0, brillo - 1);
if (pulsado && !nivel_canal_activo(canal)) pulsado = false;      // su grúa (ascensor) volvió: se rearma
if (!pulsado)
{
    var _j = nivel_jugador();
    var _pisa = (_j != noone && place_meeting(x, y - 2, _j));
    var _golpe = place_meeting(x, y, obj_hitbox_golpe);
    if (_pisa || _golpe)
    {
        pulsado = true;
        brillo = 30;
        nivel_activar_canal(canal);
        with (obj_camara) aplicar_temblor(3, 10);
        with (obj_controladores) aplicar_hitstop(4);
    }
}
image_index = pulsado ? 1 : 0;
''',
"Draw_0": r'''draw_self();
var _col = pulsado ? make_color_rgb(60, 230, 120) : make_color_rgb(230, 40, 50);
gpu_set_blendmode(bm_add);
draw_set_color(_col);
draw_set_alpha(pulsado ? 0.15 + brillo / 60 : 0.15 + 0.15 * abs(sin(t * 0.08)));
draw_circle(x, y - 6, 14 + brillo * 0.8, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

var _j = nivel_jugador();
if (!pulsado && _j != noone && point_distance(x, y, _j.x, _j.y) < 160)
    nivel_texto(x, y - 18, "Pisa o golpea el boton", c_yellow, 0.6 + 0.4 * abs(sin(t * 0.1)));
draw_set_color(c_white);
'''})

# ---------------- obj_grua + obj_plataforma_grua ----------------
OBJ["obj_grua"] = (None, None, {
"Create_0": r'''// Grúa: un carro en un riel del techo con una plataforma colgando (sólida: se puede pisar
// y engancharle el gancho). Al activarse su canal lleva la plataforma a su destino y se queda ahí.
// La instancia se coloca en el inicio del riel. Código de creación:
//   canal, recorrido (px en X, negativo = izquierda), largo (cable inicial), largo_final
//   (cable al final; -1 = igual), velocidad (px/frame), retraso (frames antes de arrancar),
//   ciclo (true = ascensor: al llegar espera "pausa" frames sin nadie encima, vuelve y su botón
//   se puede volver a pulsar; así nunca queda inalcanzable).
canal = 1;
recorrido = 320;
largo = 192;
largo_final = -1;
velocidad = 2;
retraso = 0;
ciclo = false;
pausa = 90;

iniciado = false;
volviendo = false;
espera_fin = 0;
plataforma = noone;
progreso = 0;
espera = 0;
t = 0;
x0 = x;
carro_x = x;
plat_alto = sprite_get_height(spr_nivel_plataforma);
''',
"Step_0": r'''t++;
if (!iniciado)
{
    // (en el primer Step: el código de creación ya puso los parámetros)
    iniciado = true;
    if (largo_final < 0) largo_final = largo;
    x0 = x;
    carro_x = x;
    plataforma = instance_create_layer(x, y + largo + plat_alto, layer, obj_plataforma_grua);
}
if (!instance_exists(plataforma)) exit;
if (variable_global_exists("hitstop_timer") && global.hitstop_timer > 0) exit;

// ¿El jugador está parado encima de la plataforma?
var _j = nivel_jugador();
var _encima = false;
if (_j != noone)
{
    var _p = plataforma;
    _encima = (_j.bbox_right > _p.bbox_left && _j.bbox_left < _p.bbox_right && abs(_j.bbox_bottom + 1 - _p.bbox_top) <= 3);
}

var _paso = velocidad / max(abs(recorrido), abs(largo_final - largo), 1);
if (nivel_canal_activo(canal))
{
    if (!volviendo)
    {
        if (progreso < 1)
        {
            if (espera < retraso) espera++;
            else progreso = min(1, progreso + _paso);
        }
        else if (ciclo)
        {
            espera_fin = _encima ? 0 : espera_fin + 1;
            if (espera_fin >= pausa) volviendo = true;
        }
    }
    else
    {
        progreso = max(0, progreso - _paso);
        if (progreso <= 0)
        {
            // De vuelta al inicio: se apaga el canal y el botón se puede pulsar otra vez
            volviendo = false;
            espera = 0;
            espera_fin = 0;
            global.nivel_canales[canal] = false;
        }
    }
}

var _e = progreso * progreso * (3 - 2 * progreso);       // arranca y frena suave
var _nx = x0 + recorrido * _e;
var _ny = y + lerp(largo, largo_final, _e) + plat_alto;
var _dx = _nx - plataforma.x;
var _dy = _ny - plataforma.y;

if (_dx != 0 || _dy != 0)
{
    // El jugador parado encima viaja con la plataforma
    if (_encima && _dy < 0) mec_mover_con_choque(_j, _dx, _dy);     // subiendo: primero el jugador
    plataforma.x = _nx;
    plataforma.y = _ny;
    if (_encima && _dy >= 0) mec_mover_con_choque(_j, _dx, _dy);    // bajando o de lado: después
    carro_x = _nx;
}
''',
"Draw_0": r'''var _activa = nivel_canal_activo(canal);
var _rx1 = min(x0, x0 + recorrido) - 40;
var _rx2 = max(x0, x0 + recorrido) + 40;

// Riel
draw_set_color(make_color_rgb(40, 44, 58));
draw_rectangle(_rx1, y - 16, _rx2, y - 4, false);
draw_set_color(make_color_rgb(96, 104, 128));
draw_line(_rx1, y - 16, _rx2, y - 16);
draw_set_color(c_black);
draw_rectangle(_rx1, y - 16, _rx2, y - 4, true);
draw_set_color(make_color_rgb(250, 200, 40));
for (var bx = _rx1 + 8; bx < _rx2 - 4; bx += 32) draw_rectangle(bx, y - 12, bx + 3, y - 9, false);

if (!instance_exists(plataforma)) exit;
var _p = plataforma;

// Destino (fantasma) mientras no se ha activado
if (!_activa)
{
    var _gy = y + largo_final;
    draw_set_alpha(0.25 + 0.15 * abs(sin(t * 0.06)));
    draw_set_color(make_color_rgb(250, 200, 40));
    draw_rectangle(x0 + recorrido - 48, _gy, x0 + recorrido + 48, _gy + plat_alto, true);
    draw_line(x0 + recorrido, y, x0 + recorrido, _gy);
    draw_set_alpha(1);
}

// Cable: del carro a un gancho y de ahí a las esquinas de la plataforma
var _hy = _p.bbox_top - 18;
draw_set_color(make_color_rgb(20, 20, 28));
draw_line_width(carro_x, y + 4, carro_x, _hy, 3);
draw_set_color(make_color_rgb(150, 156, 176));
draw_line(carro_x, y + 4, carro_x, _hy);
draw_line_width(carro_x, _hy, _p.bbox_left + 6, _p.bbox_top, 2);
draw_line_width(carro_x, _hy, _p.bbox_right - 6, _p.bbox_top, 2);
draw_set_color(make_color_rgb(250, 200, 40));
draw_circle(carro_x, _hy, 4, false);

// Carro
draw_set_color(make_color_rgb(60, 66, 86));
draw_rectangle(carro_x - 18, y - 20, carro_x + 18, y + 6, false);
draw_set_color(c_black);
draw_rectangle(carro_x - 18, y - 20, carro_x + 18, y + 6, true);
draw_set_color(make_color_rgb(250, 200, 40));
draw_rectangle(carro_x - 16, y - 2, carro_x + 16, y + 3, false);

// Luz de estado: roja esperando, verde activa
var _col = _activa ? make_color_rgb(60, 230, 120) : make_color_rgb(230, 40, 50);
gpu_set_blendmode(bm_add);
draw_set_color(_col);
draw_set_alpha((_activa && progreso < 1) ? 0.6 + 0.4 * abs(sin(t * 0.3)) : 0.7);
draw_circle(carro_x, y - 10, 5, false);
draw_set_alpha(0.2);
draw_circle(carro_x, y - 10, 12, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
'''})

OBJ["obj_plataforma_grua"] = ("spr_nivel_plataforma", "obj_solid", {
"Create_0": r'''// Plataforma colgante de obj_grua (hija de obj_solid: se pisa y se le engancha el gancho).
// La mueve su grúa.
image_speed = 0;
'''})

# ---------------- obj_puerta ----------------
OBJ["obj_puerta"] = ("spr_nivel_puerta", "obj_solid", {
"Create_0": r'''// Compuerta de energía (sólida). Se abre (sube y se desvanece) al activarse su canal.
// Código de creación: canal.
canal = 2;
abriendo = 0;       // 0..1
t = 0;
image_speed = 0;
''',
"Step_0": r'''t++;
if (nivel_canal_activo(canal))
{
    if (abriendo == 0) with (obj_camara) aplicar_temblor(4, 20);
    abriendo = min(1, abriendo + 1 / 40);
    y -= 2;
    if (abriendo >= 1) instance_destroy();
}
''',
"Draw_0": r'''draw_sprite_ext(sprite_index, 0, x, y, 1, 1, 0, c_white, (1 - abriendo) * (0.85 + 0.15 * sin(t * 0.4)));
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(230, 40, 160));
draw_set_alpha(0.12 * (1 - abriendo));
draw_rectangle(bbox_left - 6, bbox_top, bbox_right + 6, bbox_bottom, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

var _j = nivel_jugador();
if (abriendo == 0 && _j != noone && point_distance(x, y, _j.x, _j.y) < 200)
    nivel_texto(x, bbox_top - 8, "Cerrada: busca el boton", make_color_rgb(255, 140, 220), 0.8);
draw_set_color(c_white);
'''})

# ---------------- obj_checkpoint ----------------
OBJ["obj_checkpoint"] = ("spr_nivel_checkpoint", None, {
"Create_0": r'''// Checkpoint: al tocarlo guarda el punto de reaparición (solo si está más adelante que el
// actual) y cura 30 de vida. Sobrevive a R / morir (global.nivel_cp) mientras sigas en la room.
activo = false;
revisado = false;
anim = 0;
t = 0;
image_speed = 0;
''',
"Step_0": r'''t++;
anim = max(0, anim - 1);
var _cp = (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room == room) ? global.nivel_cp : undefined;
if (!revisado)
{
    revisado = true;
    if (!is_undefined(_cp) && _cp.x == x && _cp.y == y) activo = true;
}
var _j = nivel_jugador();
if (!activo && _j != noone && place_meeting(x, y, _j) && (is_undefined(_cp) || x > _cp.x))
{
    global.nivel_cp = { room: room, x: x, y: y };
    activo = true;
    anim = 70;
    _j.vida = min(_j.vida_maxima, _j.vida + 30);
    with (obj_checkpoint) if (id != other.id && x < other.x) activo = true;   // los anteriores quedan encendidos
}
image_index = activo ? 1 : 0;
''',
"Draw_0": r'''draw_self();
if (activo)
{
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(0, 230, 255));
    draw_set_alpha(0.18 + 0.08 * sin(t * 0.08));
    draw_circle(x - 6, y - 60, 10, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
if (anim > 0) nivel_texto(x, y - 70 - (70 - anim) * 0.4, "CHECKPOINT  +30 vida", make_color_rgb(0, 230, 255), min(1, anim / 20));
draw_set_color(c_white);
'''})

# ---------------- obj_meta ----------------
OBJ["obj_meta"] = ("spr_nivel_meta", None, {
"Create_0": r'''// Portal de salida. Código de creación: siguiente (room a la que va; -1 = la siguiente del orden).
siguiente = -1;
terminado = false;
espera = 0;
t = 0;
image_speed = 0;
''',
"Step_0": r'''t++;
image_index = (t div 12) mod 2;
var _j = nivel_jugador();
if (!terminado && _j != noone && place_meeting(x, y, _j))
{
    terminado = true;
    espera = 150;
    global.nivel_cp = undefined;
    with (obj_nivel) t_final = current_time - t_inicio;
    with (obj_camara) aplicar_temblor(4, 20);
}
if (terminado)
{
    espera--;
    if (espera <= 0)
    {
        var _dest = siguiente;
        if (_dest == -1 || !room_exists(_dest)) _dest = room_next(room);
        if (_dest != -1 && room_exists(_dest)) room_goto(_dest);
        else room_restart();
    }
}
''',
"Draw_0": r'''draw_self();
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(0, 230, 255));
draw_set_alpha(0.15 + 0.1 * sin(t * 0.1) + (terminado ? 0.3 : 0));
draw_ellipse(x - 26, y - 88, x + 26, y - 6, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
var _j = nivel_jugador();
if (!terminado && _j != noone && point_distance(x, y, _j.x, _j.y) < 260) nivel_texto(x, y - 104, "SALIDA", make_color_rgb(0, 230, 255), 0.9);
draw_set_color(c_white);
'''})


def escribir(ruta, texto):
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    nuevo = texto.replace("\r\n", "\n")
    if os.path.exists(ruta) and open(ruta, encoding="utf-8").read() == nuevo:
        return
    open(ruta, "w", encoding="utf-8", newline="\n").write(nuevo)


proj = open(YYP, encoding="utf-8").read()

def registrar(nombre, carpeta):
    global proj
    linea = '    {"id":{"name":"%s","path":"%s/%s/%s.yy",},},\n' % (nombre, carpeta, nombre, nombre)
    if '"path":"%s/%s/%s.yy"' % (carpeta, nombre, nombre) in proj:
        return
    ancla = '    {"id":{"name":"obj_plataforma_desplazable"' if carpeta == "objects" else '    {"id":{"name":"scr_mec_shield"'
    proj = proj.replace(ancla, linea + ancla, 1)

# Script
escribir(os.path.join(P, "scripts/scr_nivel/scr_nivel.gml"), SCRIPT)
escribir(os.path.join(P, "scripts/scr_nivel/scr_nivel.yy"),
         '{\n  "$GMScript":"v1",\n  "%Name":"scr_nivel",\n  "isCompatibility":false,\n  "isDnD":false,\n  "name":"scr_nivel",\n  "parent":{\n    "name":"Blank Pixel Game",\n    "path":"Blank Pixel Game.yyp",\n  },\n  "resourceType":"GMScript",\n  "resourceVersion":"2.0",\n}')
registrar("scr_nivel", "scripts")

for nombre, (sprite, padre, eventos) in OBJ.items():
    d = os.path.join(P, "objects", nombre)
    for ev, codigo in eventos.items():
        escribir(os.path.join(d, ev + ".gml"), codigo)
    escribir(os.path.join(d, nombre + ".yy"), obj_yy(nombre, list(eventos.keys()), sprite, padre))
    registrar(nombre, "objects")

open(YYP, "w", encoding="utf-8").write(proj)
print("objetos de nivel listos:", ", ".join(OBJ.keys()))
