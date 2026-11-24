# Crea el jefe demonio (Azraek), los diablitos, el corazón de vida y la hitbox de sus golpes.
# Correr desde Blank Pixel Game/arte_generado con GameMaker CERRADO:
#   python3 crear_jefe_demonio.py && python3 aplicar_sprites.py
# Sprites provisionales hechos por código (spr_nivel_demonio, spr_nivel_diablito, spr_nivel_corazon) para que
# todo funcione aunque aún no estén los de Higgsfield (spr_enemigo_demonio_*, spr_enemigo_diablito_*).
import os
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
P = os.path.dirname(AQUI)
YYP = os.path.join(P, "Blank Pixel Game.yyp")
NIV = os.path.join(AQUI, "nivel")
os.makedirs(NIV, exist_ok=True)

# ---------------- Sprites provisionales y corazón ----------------
N = (14, 14, 22, 255)
def guardar(im, n): im.save(os.path.join(NIV, n + ".png"))

for i in range(2):                                   # corazón 16x14, 2 cuadros (brillo)
    im = Image.new("RGBA", (16, 14), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.polygon([(8, 13), (1, 6), (1, 3), (3, 1), (6, 1), (8, 3), (10, 1), (13, 1), (15, 3), (15, 6)], fill=(230, 30, 80), outline=N)
    d.line([(3, 3), (5, 3)], fill=(255, 170, 200) if i == 0 else (255, 230, 240))
    d.point([(3, 4)], fill=(255, 170, 200))
    d.line([(9, 10), (12, 7)], fill=(150, 10, 50))
    guardar(im, "corazon_%d" % i)

im = Image.new("RGBA", (34, 62), (0, 0, 0, 0)); d = ImageDraw.Draw(im)   # demonio provisional
d.polygon([(10, 8), (4, 0), (12, 6)], fill=(30, 30, 36)); d.polygon([(22, 8), (30, 0), (20, 6)], fill=(30, 30, 36))
d.ellipse([10, 4, 23, 17], fill=(110, 110, 118), outline=N)
d.rectangle([9, 17, 24, 40], fill=(100, 100, 108), outline=N)
d.rectangle([10, 40, 15, 61], fill=(90, 90, 98), outline=N); d.rectangle([18, 40, 23, 61], fill=(90, 90, 98), outline=N)
d.rectangle([9, 34, 24, 42], fill=(120, 20, 30))
d.line([(24, 20), (32, 32)], fill=(255, 140, 30), width=2)
d.point([(19, 9), (21, 9)], fill=(255, 230, 60))
guardar(im, "demonio_0")

im = Image.new("RGBA", (22, 28), (0, 0, 0, 0)); d = ImageDraw.Draw(im)   # diablito provisional
d.polygon([(6, 6), (3, 0), (8, 4)], fill=(60, 10, 10)); d.polygon([(15, 6), (18, 0), (13, 4)], fill=(60, 10, 10))
d.ellipse([4, 3, 17, 15], fill=(210, 40, 40), outline=N)
d.rectangle([6, 14, 15, 23], fill=(190, 30, 30), outline=N)
d.rectangle([6, 23, 9, 27], fill=(170, 25, 25)); d.rectangle([12, 23, 15, 27], fill=(170, 25, 25))
d.point([(11, 8), (14, 8)], fill=(255, 230, 60))
d.line([(4, 20), (0, 16)], fill=(150, 20, 20))
guardar(im, "diablito_0")

# ---------------- Código ----------------
SCRIPT = r'''// ==============================
// JEFE DEMONIO "AZRAEK" y sus diablitos (propios). Funciones que corren en el contexto del jefe
// o del diablito (usan id, x, y, mirando).
// ==============================

function dem_spr(_nombre)
{
    return asset_get_index("spr" + "_enemigo_" + _nombre);
}

function dem_estado(_ia)
{
    ia = _ia;
    ia_t = 0;
    sub = 0;
}

// Mueve en X píxel a píxel sin atravesar sólidos. Devuelve true si chocó.
function dem_mover_x(_dx)
{
    var _s = sign(_dx);
    repeat (floor(abs(_dx)))
    {
        if (place_meeting(x + _s, y, obj_solid)) return true;
        x += _s;
    }
    return false;
}

// Golpe que solo daña al jugador. zona = [adelante desde, adelante hasta, arriba, abajo] desde los pies
// (adelante = hacia donde mira; arriba negativo). Sigue a su dueño mientras dura (_frames).
function dem_golpe(_a0, _a1, _arriba, _abajo, _danio, _kx, _ky, _stagger, _frames)
{
    var _g = instance_create_layer(x, y, layer, obj_golpe_demonio);
    _g.owner = id;
    _g.dueno = id;
    _g.damage = _danio;
    _g.knockback_x = _kx * mirando;
    _g.knockback_y = _ky;
    _g.stagger = _stagger;
    _g.zona = [_a0, _a1, _arriba, _abajo];
    _g.frames = _frames;
    with (_g) dem_golpe_colocar();
    return _g;
}

// Contexto: obj_golpe_demonio
function dem_golpe_colocar()
{
    if (!instance_exists(dueno)) return;
    var _m = dueno.mirando;
    var _xa = dueno.x + zona[0] * _m;
    var _xb = dueno.x + zona[1] * _m;
    x = (_xa + _xb) / 2;
    y = dueno.y + (zona[2] + zona[3]) / 2;
    image_xscale = max(1, abs(_xb - _xa)) / 32;
    image_yscale = max(1, zona[3] - zona[2]) / 32;
}

// Invoca diablitos alrededor del jefe con un destello de portal
function dem_invocar(_n)
{
    for (var i = 0; i < _n; i++)
    {
        var _sx = x + (i - (_n - 1) / 2) * 70 + mirando * 20;
        _sx = clamp(_sx, 48, room_width - 48);
        if (place_meeting(_sx, y - 1, obj_solid)) _sx = x;
        var _d = instance_create_layer(_sx, y - 1, layer, obj_diablito);
        _d.mirando = sign(x - _sx) == 0 ? 1 : -sign(x - _sx);
        array_push(portales, { x: _sx, y: y - 20, t: 30 });
    }
    with (obj_camara) aplicar_temblor(4, 14);
}

// Elige sprite y cuadro del jefe según su estado de IA
function dem_animar(_suelo)
{
    var _s = -1;
    var _i = 0;
    var _rap = (fase == 2) ? 1.4 : 1;
    var _se_mueve = abs(x - prev_x) > 0.5;
    switch (ia)
    {
        case "intro":
        case "invocar":
        case "transicion":
            _s = spr.invocar; _i = (t div 8) mod 2; break;
        case "espera":
            if (!_suelo) { _s = spr.aire; _i = 0; }
            else if (_se_mueve) { _s = spr.correr; _i = (t div 4) mod 4; }
            else { _s = spr.idle; _i = (t div 14) mod 2; }
            break;
        case "dash":
            if (ia_t < round(14 / _rap)) { _s = spr.tajo; _i = 0; }
            else { _s = spr.correr; _i = (t div 2) mod 4; }
            break;
        case "combo":
            var _L = round(12 / _rap);
            var _paso = ia_t div _L;
            var _f = ia_t mod _L;
            if (_paso >= 2) { _s = spr.lanzador; _i = (_f < 3) ? 0 : 1; }
            else { _s = spr.tajo; _i = min(2, _f div max(1, _L div 3)); }
            break;
        case "aire":
            if (sub > 0) { _s = spr.aire; _i = (sub > 6) ? 0 : 1; }
            else { _s = spr.lanzador; _i = 1; }
            break;
        case "picada":
            _s = spr.picada; _i = (ia_t < 6) ? 0 : 1; break;
        case "escape":
            _s = spr.esquiva; _i = 0; break;
        case "bolas":
            _s = spr.invocar; _i = 1; break;
        default:
            _s = spr.aturdido; _i = 0; break;
    }
    if (_s == -1) { _s = spr.idle; _i = (t div 14) mod 2; }
    if (_s == -1) { _s = spr_base; _i = 0; }
    sprite_index = _s;
    image_index = min(_i, sprite_get_number(_s) - 1);
    image_speed = 0;
}
'''

OBJ = {}

OBJ["obj_golpe_demonio"] = ("spr_hitbox", "obj_hitbox", {
"Create_0": r'''// Golpe del jefe demonio y de los diablitos (hijo de obj_hitbox): SOLO daña al jugador
// (las hitboxes normales también dañarían a los diablitos). Respeta la guardia frontal del Shield
// igual que obj_hitbox. No se destruye al pegar: dura "frames" y cada objetivo recibe un impacto.
event_inherited();
dueno = noone;
zona = [0, 0, 0, 0];
frames = 10;
golpeados = [];
visible = false;
''',
"Step_0": r'''if (variable_global_exists("hitstop_timer") && global.hitstop_timer > 0) exit;
if (!instance_exists(dueno)) { instance_destroy(); exit; }
dem_golpe_colocar();
frames--;
if (frames <= 0) instance_destroy();
''',
"Collision_obj_hurtbox": r'''if (!activo) exit;
var _t = other.owner;
if (_t == noone || !instance_exists(_t) || _t == owner) exit;
if (_t.object_index != obj_jugador) exit;
if (nivel_invulnerable()) exit;
if (array_contains(golpeados, _t)) exit;
array_push(golpeados, _t);

// Guardia frontal (Shield): mismo criterio que obj_hitbox
if (variable_instance_exists(_t, "bloqueando") && _t.bloqueando && variable_instance_exists(_t, "mirando")
    && instance_exists(owner) && _t.mirando == sign(owner.x - _t.x))
{
    _t.bloqueo_golpes_recibidos++;
    with (obj_controladores) aplicar_hitstop(3);
    if (_t.bloqueo_golpes_recibidos >= _t.bloqueo_resistencia)
    {
        _t.bloqueando = false;
        _t.bloqueo_golpes_recibidos = 0;
        _t.bloqueo_recovery_timer = _t.bloqueo_recovery;
    }
    exit;
}

var _d = damage, _kx = knockback_x, _ky = knockback_y, _st = stagger;
with (_t) recibir_impacto(_d, _kx, _ky, _st);
with (obj_controladores) aplicar_hitstop(4);
with (obj_camara) aplicar_temblor(3, 8);
if (instance_exists(owner) && variable_instance_exists(owner, "conecto")) owner.conecto = true;
'''})

OBJ["obj_jefe_demonio"] = ("spr_nivel_demonio", "obj_enemigo", {
"Create_0": r'''event_inherited();
// JEFE: AZRAEK, EL DESOLLADOR. Del tamaño del jugador, rápido y escurridizo, con combos en el suelo y en
// el aire (lanza al jugador y lo sigue), 2 fases e invocación de diablitos que sueltan corazones.
// Hijo de obj_enemigo: recibe los golpes del jugador como cualquier enemigo. Código de creación: siguiente.
nombre_jefe = "AZRAEK, EL DESOLLADOR";
siguiente = -1;                 // room a la que lleva el portal al vencerlo (-1 = la siguiente del orden)

vida_maxima = 240;
vida = vida_maxima;
vel_caminar = 0;                // se mueve con su propia IA
caminar_habilitado = false;
evitar_bordes = false;
lanzable = true;
impacto_estampar = 12;
danio_estampado = 6;
estilo_favorecido = "";

spr_base = sprite_index;
spr = {
    idle: dem_spr("demonio_idle"), correr: dem_spr("demonio_correr"), tajo: dem_spr("demonio_tajo"),
    lanzador: dem_spr("demonio_lanzador"), aire: dem_spr("demonio_aire"), picada: dem_spr("demonio_picada"),
    invocar: dem_spr("demonio_invocar"), aturdido: dem_spr("demonio_aturdido"), esquiva: dem_spr("demonio_esquiva"),
};

fase = 1;
ia = "intro";
ia_t = 0;
sub = 0;
t = 0;
invulnerable = 0;
golpes_racha = 0;               // golpes recibidos seguidos: al pasar el límite rompe el combo (escape)
racha_timer = 0;
escapar = false;
cooldown = 60;
t_invocar = 240;
diablitos_max = 3;
conecto = false;
aire_golpes = 0;
dir_escape = 1;
alpha = 1;
aura = 0;
estela = [];
portales = [];
prev_x = x;
inicio_y = y;
mirando = -1;

// Daño recibido: sin daño durante la invulnerabilidad; cuenta la racha para escapar
recibir_base = recibir_impacto;
recibir_impacto = function(_d, _kx, _ky, _st)
{
    if (invulnerable > 0 || ia == "intro" || ia == "transicion") return;
    recibir_base(_d, _kx, _ky, _st * 0.6);
    if (vida <= 0) return;
    golpes_racha++;
    racha_timer = 45;
    if (golpes_racha >= ((fase == 1) ? 6 : 4)) escapar = true;
};
''',
"Step_0": r'''event_inherited();
if (variable_global_exists("hitstop_timer") && global.hitstop_timer > 0) exit;
mask_index = spr_base;

t++;
ia_t++;
invulnerable = max(0, invulnerable - 1);
racha_timer = max(0, racha_timer - 1);
if (racha_timer == 0) golpes_racha = 0;
t_invocar = max(0, t_invocar - 1);
cooldown = max(0, cooldown - 1);
aura = (fase == 2) ? 1 : aura;

for (var i = array_length(estela) - 1; i >= 0; i--) { estela[i].a -= 0.05; if (estela[i].a <= 0) array_delete(estela, i, 1); }
for (var i = array_length(portales) - 1; i >= 0; i--) { portales[i].t--; if (portales[i].t <= 0) array_delete(portales, i, 1); }

var _suelo = place_meeting(x, y + 1, obj_solid);
var _j = nivel_jugador();
if (_j == noone) { dem_animar(_suelo); prev_x = x; exit; }
var _dx = _j.x - x;
var _dist = abs(_dx);
var _hacia = (_dx >= 0) ? 1 : -1;
var _rap = (fase == 2) ? 1.4 : 1;

// Fase 2 a mitad de vida
if (fase == 1 && vida <= vida_maxima * 0.5 && ia != "transicion")
{
    dem_estado("transicion");
    with (obj_golpe_demonio) if (dueno == other.id) instance_destroy();
}
// Rompe-combos: tras una racha de golpes escapa (invulnerable) aunque esté aturdido o en el aire
if (escapar && ia != "transicion" && ia != "intro")
{
    escapar = false;
    golpes_racha = 0;
    aturdido_timer = 0;
    if (estado == EnemyState.KNOCKED_DOWN) estado = EnemyState.NORMAL;
    dem_estado("escape");
}
// Aturdido o derribado por el jugador: deja que la física del enemigo base lo mueva
var _inmovil = (estado == EnemyState.KNOCKED_DOWN || aturdido_timer > 0) && ia != "escape" && ia != "transicion" && ia != "intro";
if (_inmovil)
{
    if (ia != "aturdido") dem_estado("aturdido");
    dem_animar(_suelo);
    prev_x = x;
    exit;
}
if (ia == "aturdido") { dem_estado("espera"); cooldown = 10; }

switch (ia)
{
    case "intro":
        invulnerable = 2;
        mirando = _hacia;
        if (ia_t == 50) with (obj_camara) aplicar_temblor(6, 30);
        if (ia_t >= 90) { dem_estado("espera"); cooldown = 30; }
        break;

    case "espera":
        mirando = _hacia;
        var _ideal = (fase == 1) ? 170 : 130;
        var _v = 3 * _rap;
        if (_suelo)
        {
            if (_dist > _ideal + 30) dem_mover_x(_hacia * _v);
            else if (_dist < _ideal - 40) dem_mover_x(-_hacia * _v * 0.8);
            else dem_mover_x(sin(t * 0.07) * _v * 0.6);
        }
        if (cooldown <= 0 && _suelo)
        {
            var _r = irandom(99);
            if (_j.y < y - 110 && _r < 60)
            {
                // El jugador está arriba (plataforma): salta hacia él y lo busca en el aire
                dem_estado("aire");
                vsp = -13.5;
                aire_golpes = 0;
            }
            else if (t_invocar <= 0 && instance_number(obj_diablito) < diablitos_max && _r < 30) dem_estado("invocar");
            else if (fase == 2 && _r < 50) dem_estado("bolas");
            else if (_dist < 80) dem_estado("combo");
            else dem_estado("dash");
        }
        break;

    case "dash":
        var _wind = round(14 / _rap);
        var _dur = round(16 / _rap) + 2;
        if (ia_t < _wind) mirando = _hacia;
        else
        {
            if (ia_t == _wind) { conecto = false; dem_golpe(-6, 40, -54, 0, 8, 5, -2, 14, _dur); }
            var _choco = dem_mover_x(mirando * 10 * _rap);
            if (ia_t mod 2 == 0) array_push(estela, { s: sprite_index, i: image_index, x: x, y: y, m: mirando, a: 0.5 });
            if (ia_t >= _wind + _dur || _choco)
            {
                if (conecto) dem_estado("combo");
                else { dem_estado("espera"); cooldown = round(30 / _rap); }
            }
        }
        break;

    case "combo":
        // Tres zarpazos; el tercero lanza al jugador hacia arriba y, si conecta, sigue en el aire
        var _L = round(12 / _rap);
        var _paso = ia_t div _L;
        var _f = ia_t mod _L;
        if (_f == 0) { mirando = _hacia; if (_paso == 2) conecto = false; }
        if (_f == 2)
        {
            if (_paso < 2) dem_golpe(-6, 42, -56, 0, 6, 2, -1, 10, 5);
            else if (_paso == 2) dem_golpe(-6, 42, -72, 0, 8, 1, -11, 30, 6);
        }
        if (_f < 5 && _paso < 3) dem_mover_x(mirando * 2);
        if (_paso >= 3)
        {
            if (conecto) { dem_estado("aire"); vsp = -12.5; aire_golpes = 0; }
            else { dem_estado("espera"); cooldown = round(40 / _rap); }
        }
        break;

    case "aire":
        // Combo aéreo: persigue al jugador en el aire, lo corta 2 (fase 2: 3) veces y remata en picada
        var _max = (fase == 1) ? 2 : 3;
        mirando = _hacia;
        if (abs(_dx) > 20) dem_mover_x(clamp(_dx * 0.2, -5 * _rap, 5 * _rap));
        if (sub > 0) { sub--; vsp = min(vsp, 0.5); }
        if (sub == 0 && ia_t > 8 && aire_golpes < _max && point_distance(x, y - 30, _j.x, _j.y - 30) < 72)
        {
            aire_golpes++;
            sub = round(12 / _rap);
            dem_golpe(-10, 44, -72, 10, 5, 1, -4, 12, 6);
        }
        if (aire_golpes >= _max && sub == 0) dem_estado("picada");
        else if (_suelo && ia_t > 10 && sub == 0) { dem_estado("espera"); cooldown = 20; }
        else if (ia_t > 100) dem_estado("picada");
        break;

    case "picada":
        if (ia_t < 6) vsp = -1;
        else vsp = 15;
        if (ia_t == 6) dem_golpe(-18, 30, -60, 24, 9, 2, 9, 20, 40);
        if (_suelo && ia_t > 6)
        {
            with (obj_golpe_demonio) if (dueno == other.id) instance_destroy();
            dem_golpe(-90, 90, -28, 0, 8, 0, -7, 25, 6);       // onda al caer
            instance_create_layer(x, y, layer, obj_fx_estampada, { fuerza: 0.6, radio: 90 });
            with (obj_camara) aplicar_temblor(7, 16);
            dem_estado("espera");
            cooldown = round(35 / _rap);
        }
        break;

    case "escape":
        invulnerable = max(invulnerable, 2);
        if (fase == 1)
        {
            // Voltereta hacia atrás (si hay pared detrás, salta por encima del jugador)
            if (ia_t == 1)
            {
                vsp = -9;
                hsp = 0;
                dir_escape = -_hacia;
                if (place_meeting(x + dir_escape * 48, y - 8, obj_solid)) dir_escape = _hacia;
            }
            dem_mover_x(dir_escape * 7);
            if (ia_t mod 2 == 0) array_push(estela, { s: sprite_index, i: image_index, x: x, y: y, m: mirando, a: 0.4 });
            if ((ia_t > 8 && _suelo) || ia_t > 45)
            {
                if (irandom(1) == 0) dem_estado("dash");
                else { dem_estado("espera"); cooldown = 15; }
            }
        }
        else
        {
            // Teletransporte detrás del jugador y contraataque
            if (ia_t < 10) alpha = 1 - ia_t / 10;
            else if (ia_t == 10)
            {
                array_push(portales, { x: x, y: y - 30, t: 20 });
                var _lado = choose(-1, 1);
                var _nx = clamp(_j.x + _lado * 140, 64, room_width - 64);
                if (place_meeting(_nx, _j.y - 2, obj_solid)) _nx = clamp(_j.x - _lado * 140, 64, room_width - 64);
                x = _nx;
                y = _j.y;
                var _k = 0;
                while (place_meeting(x, y, obj_solid) && _k < 96) { y -= 2; _k++; }
                hsp = 0;
                vsp = 0;
                mirando = (_j.x >= x) ? 1 : -1;
                array_push(portales, { x: x, y: y - 30, t: 20 });
            }
            else if (ia_t < 18) alpha = (ia_t - 10) / 8;
            else { alpha = 1; dem_estado(choose("combo", "dash")); }
        }
        break;

    case "invocar":
        mirando = _hacia;
        if (ia_t == 24) { dem_invocar((fase == 1) ? 2 : 3); t_invocar = (fase == 1) ? 540 : 400; }
        if (ia_t >= 50) { dem_estado("espera"); cooldown = 20; }
        break;

    case "bolas":
        // Fase 2: salta y lanza 3 bolas de fuego en abanico (se pueden devolver con el parry)
        if (ia_t == 1 && _suelo) vsp = -12;
        if (sub == 0 && ia_t > 5 && vsp >= 0) sub = 1;
        if (sub >= 1)
        {
            sub++;
            vsp = min(vsp, 0);
            mirando = _hacia;
            if (sub == 8 || sub == 18 || sub == 28)
            {
                var _desv = (sub == 8) ? -12 : ((sub == 18) ? 0 : 12);
                var _dir = point_direction(x, y - 34, _j.x, _j.y - 30) + _desv;
                var _p = instance_create_layer(x + mirando * 14, y - 34, layer, obj_proyectil);
                _p.owner = id;
                _p.equipo = "enemigo";
                _p.vx = lengthdir_x(5.5, _dir);
                _p.vy = lengthdir_y(5.5, _dir);
                _p.damage = 8;
            }
            if (sub >= 36) { dem_estado("espera"); cooldown = 30; }
        }
        if (ia_t > 120) dem_estado("espera");
        break;

    case "transicion":
        invulnerable = 2;
        hsp = 0;
        aura = min(1, ia_t / 60);
        mirando = _hacia;
        if (ia_t == 1) { with (obj_controladores) aplicar_hitstop(12); with (obj_camara) aplicar_temblor(10, 40); }
        if (ia_t == 30)
        {
            // Rugido: onda que empuja al jugador
            instance_create_layer(x, y, layer, obj_fx_estampada, { fuerza: 1, radio: 160 });
            if (point_distance(x, y, _j.x, _j.y) < 180 && !nivel_invulnerable())
                with (_j) recibir_impacto(5, sign(x - other.x) * 9, -6, 0);
        }
        if (ia_t == 50) dem_invocar(2);
        if (ia_t >= 80) { fase = 2; diablitos_max = 5; dem_estado("escape"); }
        break;
}

dem_animar(place_meeting(x, y + 1, obj_solid));
prev_x = x;
''',
"Draw_0": r'''// Estela de las embestidas y del escape
var _col_estela = (fase == 2) ? make_color_rgb(255, 40, 40) : make_color_rgb(255, 120, 40);
gpu_set_blendmode(bm_add);
for (var i = 0; i < array_length(estela); i++)
{
    var _e = estela[i];
    draw_sprite_ext(_e.s, _e.i, _e.x, _e.y, _e.m, 1, 0, _col_estela, _e.a);
}
// Aura roja en la fase 2
if (aura > 0)
{
    draw_set_color(make_color_rgb(255, 30, 30));
    draw_set_alpha(aura * (0.18 + 0.08 * sin(t * 0.2)));
    draw_ellipse(x - 30, y - 70, x + 30, y + 4, false);
}
// Portales de invocación / teletransporte
for (var i = 0; i < array_length(portales); i++)
{
    var _p = portales[i];
    draw_set_color(make_color_rgb(200, 30, 60));
    draw_set_alpha(_p.t / 30);
    draw_ellipse(_p.x - 18, _p.y - 28 + _p.t * 0.3, _p.x + 18, _p.y + 28 - _p.t * 0.3, false);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

var _a = alpha;
if (invulnerable > 0 && ia == "escape" && fase == 1) _a *= 0.6;
var _col = (aturdido_timer > 0) ? make_color_rgb(255, 225, 140) : c_white;
if (flash_timer > 0) gpu_set_fog(true, c_white, 0, 1);
draw_sprite_ext(sprite_index, image_index, x, y, mirando, 1, 0, _col, _a);
if (flash_timer > 0) gpu_set_fog(false, c_white, 0, 0);

// Aviso de la embestida: destello en los ojos
if (ia == "dash" && ia_t < round(14 / ((fase == 2) ? 1.4 : 1)))
{
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(255, 230, 60));
    draw_set_alpha(0.8);
    draw_circle(x + mirando * 6, y - sprite_get_height(sprite_index) + 12, 4 + (ia_t mod 4), false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
draw_set_color(c_white);
''',
"Draw_64": r'''// Barra de vida del jefe
var _gw = display_get_gui_width();
var _gh = display_get_gui_height();
var _w = 520;
var _x1 = _gw / 2 - _w / 2;
var _y1 = _gh - 60;
draw_set_halign(fa_center);
draw_set_color(c_black);
draw_text(_gw / 2 + 1, _y1 - 21, nombre_jefe);
draw_set_color((fase == 2) ? make_color_rgb(255, 80, 80) : make_color_rgb(255, 170, 60));
draw_text(_gw / 2, _y1 - 22, nombre_jefe + ((fase == 2) ? "  -  FASE 2" : ""));
draw_set_halign(fa_left);
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(_x1 - 3, _y1 - 3, _x1 + _w + 3, _y1 + 13, false);
draw_set_alpha(1);
draw_set_color((fase == 2) ? make_color_rgb(220, 30, 40) : make_color_rgb(240, 120, 30));
draw_rectangle(_x1, _y1, _x1 + _w * max(0, vida) / vida_maxima, _y1 + 10, false);
draw_set_color(c_white);
draw_line(_x1 + _w / 2, _y1 - 2, _x1 + _w / 2, _y1 + 12);
''',
"Destroy_0": r'''// Vencido: explosión, los diablitos desaparecen (sin corazón) y aparece el portal de salida
with (obj_diablito) { sin_premio = true; instance_destroy(); }
with (obj_golpe_demonio) instance_destroy();
instance_create_layer(x, y, layer, obj_fx_estampada, { fuerza: 1.4, radio: 140 });
with (obj_camara) aplicar_temblor(12, 40);
var _m = instance_create_layer(room_width / 2, inicio_y, layer, obj_meta);
_m.siguiente = siguiente;
'''})

OBJ["obj_diablito"] = ("spr_nivel_diablito", "obj_enemigo", {
"Create_0": r'''event_inherited();
// Diablito invocado por el jefe: poca vida, rápido, zarpazo débil. Al morir puede soltar un corazón (40 %).
// Usa la caminata/persecución del enemigo base y un ataque propio (obj_golpe_demonio: no daña al jefe).
vida_maxima = 14;
vida = vida_maxima;
vel_caminar = 1.8;
rango_deteccion = 520;
persecucion_duracion = 90;
evitar_bordes = true;
impacto_estampar = 8;
estilo_favorecido = "";
spr_base = sprite_index;
spr = { idle: dem_spr("diablito_idle"), correr: dem_spr("diablito_correr"),
        ataque: dem_spr("diablito_ataque"), aire: dem_spr("diablito_aire") };
atk_t = 0;
atk_cd = 40;
conecto = false;
sin_premio = false;
prev_x = x;
''',
"Step_0": r'''event_inherited();
if (variable_global_exists("hitstop_timer") && global.hitstop_timer > 0) exit;
mask_index = spr_base;
atk_cd = max(0, atk_cd - 1);

var _j = nivel_jugador();
var _suelo = place_meeting(x, y + 1, obj_solid);
var _libre = (estado == EnemyState.NORMAL && aturdido_timer <= 0 && _suelo);
if (atk_t > 0)
{
    atk_t--;
    if (atk_t == 8) dem_golpe(-4, 28, -30, 0, 5, 3, -2, 6, 4);
}
else if (_libre && atk_cd == 0 && _j != noone && abs(_j.x - x) < 34 && abs(_j.y - y) < 40)
{
    mirando = (_j.x >= x) ? 1 : -1;
    atk_t = 16;
    atk_cd = 70;
}
caminar_habilitado = (atk_t == 0);

// Animación (si faltan los sprites de Higgsfield usa el provisional)
var _s = spr.idle, _i = (current_time div 160) mod 2;
if (!_suelo || estado == EnemyState.AIRBORNE) { _s = spr.aire; _i = 0; }
else if (atk_t > 0) { _s = spr.ataque; _i = (atk_t > 8) ? 0 : 1; }
else if (abs(x - prev_x) > 0.3) { _s = spr.correr; _i = (current_time div 90) mod 2; }
if (_s == -1) _s = spr.idle;
if (_s == -1) { _s = spr_base; _i = 0; }
sprite_index = _s;
image_index = min(_i, sprite_get_number(_s) - 1);
image_speed = 0;
prev_x = x;
''',
"Destroy_0": r'''// 40 % de probabilidad de soltar un corazón
if (vida <= 0 && !sin_premio && random(1) < 0.4) instance_create_layer(x, y - 20, layer, obj_corazon);
'''})

OBJ["obj_corazon"] = ("spr_nivel_corazon", None, {
"Create_0": r'''// Corazón de vida que sueltan los diablitos: cae, flota, se acerca al jugador y cura "cura".
vsp = -4;
hsp = random_range(-1.5, 1.5);
t = 0;
vida_t = 720;
cura = 15;
recogido = 0;
image_speed = 0;
''',
"Step_0": r'''t++;
if (recogido > 0) { recogido--; y -= 1; if (recogido <= 0) instance_destroy(); exit; }
vida_t--;
if (vida_t <= 0) { instance_destroy(); exit; }

var _j = nivel_jugador();
if (_j != noone && point_distance(x, y, _j.x, _j.y - 30) < 70)
{
    // Imán hacia el jugador
    x = lerp(x, _j.x, 0.18);
    y = lerp(y, _j.y - 30, 0.18);
    vsp = 0;
    if (point_distance(x, y, _j.x, _j.y - 30) < 18)
    {
        _j.vida = min(_j.vida_maxima, _j.vida + cura);
        recogido = 40;
    }
    exit;
}
vsp = min(vsp + 0.3, 8);
if (place_meeting(x, y + vsp, obj_solid))
{
    while (!place_meeting(x, y + sign(vsp), obj_solid)) y += sign(vsp);
    vsp = 0;
    hsp = 0;
}
y += vsp;
if (!place_meeting(x + hsp, y, obj_solid)) x += hsp; else hsp = 0;
''',
"Draw_0": r'''if (recogido > 0) { nivel_texto(x, y - 10, "+" + string(cura) + " VIDA", make_color_rgb(255, 90, 140), recogido / 40); exit; }
if (vida_t < 150 && (t div 4) mod 2 == 0) exit;
var _b = sin(t * 0.12) * 2;
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(255, 60, 120));
draw_set_alpha(0.25 + 0.1 * sin(t * 0.2));
draw_circle(x, y - 7 + _b, 11, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_sprite(sprite_index, (t div 20) mod 2, x, y + _b);
draw_set_color(c_white);
'''})

EV = {"Create_0": (0, 0, None), "Step_0": (0, 3, None), "Draw_0": (0, 8, None), "Draw_64": (64, 8, None),
      "Destroy_0": (0, 1, None), "Collision_obj_hurtbox": (0, 4, "obj_hurtbox")}


def obj_yy(nombre, eventos, sprite=None, padre=None):
    lineas = []
    for e in eventos:
        num, tipo, col = EV[e]
        colj = '{"name":"%s","path":"objects/%s/%s.yy",}' % (col, col, col) if col else "null"
        lineas.append('    {"$GMEvent":"v1","%%Name":"","collisionObjectId":%s,"eventNum":%d,"eventType":%d,"isDnD":false,"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},\n' % (colj, num, tipo))
    spr = '{\n    "name":"%s",\n    "path":"sprites/%s/%s.yy",\n  }' % (sprite, sprite, sprite) if sprite else "null"
    par = '{\n    "name":"%s",\n    "path":"objects/%s/%s.yy",\n  }' % (padre, padre, padre) if padre else "null"
    vis = "false" if nombre == "obj_golpe_demonio" else "true"
    return ('{\n  "$GMObject":"",\n  "%%Name":"%s",\n  "eventList":[\n%s  ],\n  "managed":true,\n  "name":"%s",\n  "overriddenProperties":[],\n'
            '  "parent":{\n    "name":"Blank Pixel Game",\n    "path":"Blank Pixel Game.yyp",\n  },\n  "parentObjectId":%s,\n  "persistent":false,\n'
            '  "physicsAngularDamping":0.1,\n  "physicsDensity":0.5,\n  "physicsFriction":0.2,\n  "physicsGroup":1,\n  "physicsKinematic":false,\n'
            '  "physicsLinearDamping":0.1,\n  "physicsObject":false,\n  "physicsRestitution":0.1,\n  "physicsSensor":false,\n  "physicsShape":1,\n'
            '  "physicsShapePoints":[],\n  "physicsStartAwake":true,\n  "properties":[],\n  "resourceType":"GMObject",\n  "resourceVersion":"2.0",\n'
            '  "solid":false,\n  "spriteId":%s,\n  "spriteMaskId":null,\n  "visible":%s,\n}') % (nombre, "".join(lineas), nombre, par, spr, vis)


def escribir(ruta, texto):
    os.makedirs(os.path.dirname(ruta), exist_ok=True)
    open(ruta, "w", encoding="utf-8", newline="\n").write(texto)


proj = open(YYP, encoding="utf-8").read()
def registrar(nombre, carpeta):
    global proj
    if '"path":"%s/%s/%s.yy"' % (carpeta, nombre, nombre) in proj: return
    linea = '    {"id":{"name":"%s","path":"%s/%s/%s.yy",},},\n' % (nombre, carpeta, nombre, nombre)
    ancla = '    {"id":{"name":"obj_plataforma_desplazable"' if carpeta == "objects" else '    {"id":{"name":"scr_mec_shield"'
    proj = proj.replace(ancla, linea + ancla, 1)

escribir(os.path.join(P, "scripts/scr_jefe_demonio/scr_jefe_demonio.gml"), SCRIPT)
escribir(os.path.join(P, "scripts/scr_jefe_demonio/scr_jefe_demonio.yy"),
         open(os.path.join(P, "scripts/scr_nivel/scr_nivel.yy"), encoding="utf-8").read().replace("scr_nivel", "scr_jefe_demonio"))
registrar("scr_jefe_demonio", "scripts")
for nombre, (sprite, padre, eventos) in OBJ.items():
    d = os.path.join(P, "objects", nombre)
    for ev, codigo in eventos.items():
        escribir(os.path.join(d, ev + ".gml"), codigo)
    escribir(os.path.join(d, nombre + ".yy"), obj_yy(nombre, list(eventos.keys()), sprite, padre))
    registrar(nombre, "objects")
open(YYP, "w", encoding="utf-8").write(proj)
print("jefe demonio listo:", ", ".join(OBJ.keys()))
