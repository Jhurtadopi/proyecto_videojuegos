event_inherited();
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
