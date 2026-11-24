// ==============================
// GANCHO A ENEMIGOS (propio; no modifica scr_mec_gancho)
// Click derecho con la mira sobre un enemigo:
//   - click corto: lo ATRAE hacia el jugador y lo aturde
//   - mantener: lo ARRASTRA colgando del cable hacia la mira; al soltar, lo LANZA en esa
//     dirección (hacia abajo lo estampa contra el suelo)
//   - con W (o si el enemigo no se puede mover, ej. torreta) el jugador VA hacia él
// Corre antes de mec_gancho_inicio y le sube gancho_cooldown para que el gancho normal
// no se dispare con el mismo click. Contexto: obj_mecanicas_jugador.
// ==============================

enum GanchoEnemigo
{
    INACTIVO,
    LANZANDO,       // la punta vuela hacia el enemigo
    ATRAYENDO,      // el enemigo viaja hacia el jugador
    YENDO,          // el jugador viaja hacia el enemigo
    ARRASTRANDO     // el enemigo cuelga del cable y sigue a la mira hasta soltar el click
}

function mec_gancho_enemigo_crear()
{
    ge_estado = GanchoEnemigo.INACTIVO;
    ge_objetivo = noone;
    ge_ir = false;                  // true = el jugador va hacia el enemigo
    ge_punta_x = 0;
    ge_punta_y = 0;
    ge_timer = 0;

    ge_radio_apuntar = 28;          // px entre la mira y el enemigo para engancharlo
    ge_vel_punta = 48;              // velocidad de la punta (igual que el gancho normal)
    ge_vel_atraer = 16;             // velocidad del enemigo atraído
    ge_vel_ir = 20;                 // velocidad del jugador yendo hacia el enemigo
    ge_distancia_final = 44;        // px a los que se detiene (enemigo atraído o jugador que llega)
    ge_duracion_max = 40;           // frames máximos de viaje (por si algo lo bloquea)
    ge_danio = 2;
    ge_stagger = 40;                // aturde al enganchar: da tiempo a seguir el combo
    ge_cooldown = 20;
    ge_objetivo_mira = noone;       // enemigo bajo la mira (para dibujar el anillo)

    // ARRASTRE (mantener el click)
    ge_radio_arrastre = 72;         // px del pecho del jugador al punto donde cuelga el enemigo
    ge_seguir = 0.35;               // qué tan rápido sigue el enemigo a ese punto (0-1)
    ge_vel_arrastre_max = 18;
    ge_arrastre_max = 120;          // frames máximos arrastrando (luego se lanza solo)
    ge_vel_lanzar = 16;             // velocidad del lanzamiento al soltar
    ge_danio_lanzar = 4;

    // ENEMIGO COMO PROYECTIL: el lanzado choca con otros enemigos y ambos reciben daño
    ge_proyectiles = [];            // [{e, t, golpeados}]
    ge_choque_danio = 10;           // al enemigo golpeado
    ge_choque_danio_lanzado = 6;    // al enemigo lanzado
    ge_choque_stagger = 30;
}

// Revisa los enemigos lanzados con el gancho: si chocan con otro enemigo, daño a los dos
function mec_gancho_enemigo_proyectiles()
{
    for (var i = array_length(ge_proyectiles) - 1; i >= 0; i--)
    {
        var _pr = ge_proyectiles[i];
        _pr.t--;
        var _e = _pr.e;
        if (!instance_exists(_e) || _pr.t <= 0) { array_delete(ge_proyectiles, i, 1); continue; }
        var _vel = abs(_e.hsp) + abs(_e.vsp);
        if (_vel < 3 && _pr.t < 40) { array_delete(ge_proyectiles, i, 1); continue; }    // ya se detuvo

        var _lista = ds_list_create();
        var _n = 0;
        with (_e) _n = instance_place_list(x, y, obj_enemigo, _lista, false);
        for (var k = 0; k < _n; k++)
        {
            var _o = _lista[| k];
            if (_o == _e || !instance_exists(_o) || array_contains(_pr.golpeados, _o)) continue;
            array_push(_pr.golpeados, _o);
            var _dir = (_e.hsp == 0) ? sign(_o.x - _e.x) : sign(_e.hsp);
            if (_dir == 0) _dir = 1;
            var _d1 = ge_choque_danio, _d2 = ge_choque_danio_lanzado, _st = ge_choque_stagger;
            with (_o) recibir_impacto(_d1, _dir * 7, -5, _st);
            if (instance_exists(_e)) with (_e) recibir_impacto(_d2, -_dir * 2, -3, _st);
            with (obj_controladores) aplicar_hitstop(6);
            with (obj_camara) aplicar_temblor(5, 10);
            if (instance_exists(_o)) instance_create_layer((_o.x + _e.x) / 2, _o.y, "Instances", obj_fx_estampada, { fuerza: 0.3, radio: 40 });
            if (!instance_exists(_e)) break;
        }
        ds_list_destroy(_lista);
    }
}

function mec_gancho_enemigo_activo()
{
    return ge_estado != GanchoEnemigo.INACTIVO;
}

// Centro del enemigo (su bbox)
function mec_gancho_enemigo_centro(_e)
{
    return [(_e.bbox_left + _e.bbox_right) / 2, (_e.bbox_top + _e.bbox_bottom) / 2];
}

// Enemigo enganchable bajo la mira: cerca del cursor, a alcance y con línea de visión
function mec_gancho_enemigo_buscar()
{
    var _o = mec_gancho_origen(jugador);
    var _mejor = noone;
    var _dmin = ge_radio_apuntar;
    var _alcance = gancho_alcance_max;

    with (obj_enemigo)
    {
        var _dx = max(bbox_left - mouse_x, 0, mouse_x - bbox_right);
        var _dy = max(bbox_top - mouse_y, 0, mouse_y - bbox_bottom);
        var _d = point_distance(0, 0, _dx, _dy);
        var _cx = (bbox_left + bbox_right) / 2;
        var _cy = (bbox_top + bbox_bottom) / 2;

        if (_d <= _dmin
            && point_distance(_o[0], _o[1], _cx, _cy) <= _alcance
            && collision_line(_o[0], _o[1], _cx, _cy, obj_solid, false, true) == noone)
        {
            _mejor = id;
            _dmin = _d;
        }
    }

    return _mejor;
}

function mec_gancho_enemigo_terminar()
{
    ge_estado = GanchoEnemigo.INACTIVO;
    ge_objetivo = noone;
    gancho_cooldown = max(gancho_cooldown, ge_cooldown);
}

// Begin Step, ANTES de mec_gancho_inicio
function mec_gancho_enemigo_inicio()
{
    ge_objetivo_mira = noone;

    if (ge_estado != GanchoEnemigo.INACTIVO)
    {
        // Bloquea el gancho normal mientras dure (mec_gancho_inicio solo dispara con cooldown 0)
        gancho_cooldown = max(gancho_cooldown, 2);
        if (mec_dash_activo()) mec_gancho_enemigo_terminar();     // el dash lo cancela
        return;
    }

    if (gancho_estado != GanchoEstado.INACTIVO || gancho_cooldown > 0) return;
    if (mec_dash_activo() || mec_parry_golpeando()) return;

    ge_objetivo_mira = mec_gancho_enemigo_buscar();
    if (ge_objetivo_mira == noone || !mouse_check_button_pressed(mb_right)) return;

    var _o = mec_gancho_origen(jugador);
    ge_objetivo = ge_objetivo_mira;
    ge_ir = keyboard_check(ord("W")) || !ge_objetivo.lanzable;
    ge_punta_x = _o[0];
    ge_punta_y = _o[1];
    ge_timer = 0;
    ge_estado = GanchoEnemigo.LANZANDO;
    gancho_cooldown = 2;                                   // el gancho normal no se dispara este frame
    mirando = (ge_objetivo.x >= jugador.x) ? 1 : -1;
    if (variable_instance_exists(id, "gancho_mano")) gancho_mano = -gancho_mano;   // alterna mano
}

// End Step, DESPUÉS de mec_gancho_fin
function mec_gancho_enemigo_fin()
{
    mec_gancho_enemigo_proyectiles();
    if (ge_estado == GanchoEnemigo.INACTIVO) return;

    var _j = jugador;
    if (!instance_exists(ge_objetivo) || !instance_exists(_j))
    {
        mec_gancho_enemigo_terminar();
        return;
    }

    var _e = ge_objetivo;
    var _c = mec_gancho_enemigo_centro(_e);
    var _o = mec_gancho_origen(_j);
    ge_timer++;

    switch (ge_estado)
    {
        case GanchoEnemigo.LANZANDO:
            var _dist = point_distance(ge_punta_x, ge_punta_y, _c[0], _c[1]);
            if (_dist <= ge_vel_punta)
            {
                ge_punta_x = _c[0];
                ge_punta_y = _c[1];
                var _dn = ge_danio;
                var _st = ge_stagger;
                with (_e) recibir_impacto(_dn, 0, 0, _st);
                if (!instance_exists(_e)) { mec_gancho_enemigo_terminar(); return; }
                if (ge_ir) ge_estado = GanchoEnemigo.YENDO;
                else if (mouse_check_button(mb_right)) ge_estado = GanchoEnemigo.ARRASTRANDO;   // sigue apretado
                else ge_estado = GanchoEnemigo.ATRAYENDO;
                ge_timer = 0;
            }
            else
            {
                var _dir = point_direction(ge_punta_x, ge_punta_y, _c[0], _c[1]);
                ge_punta_x += lengthdir_x(ge_vel_punta, _dir);
                ge_punta_y += lengthdir_y(ge_vel_punta, _dir);
            }
        break;

        case GanchoEnemigo.ATRAYENDO:
            // El enemigo viaja hacia el pecho del jugador (su Step suma la gravedad: se compensa)
            ge_punta_x = _c[0];
            ge_punta_y = _c[1];
            var _d_atr = point_distance(_c[0], _c[1], _o[0], _o[1]);
            if (_d_atr <= ge_distancia_final || ge_timer > ge_duracion_max)
            {
                _e.hsp *= 0.15;
                _e.vsp = -3;        // queda un instante en el aire, listo para el combo
                mec_gancho_enemigo_terminar();
            }
            else
            {
                var _dir_atr = point_direction(_c[0], _c[1], _o[0], _o[1]);
                _e.hsp = lengthdir_x(ge_vel_atraer, _dir_atr);
                _e.vsp = lengthdir_y(ge_vel_atraer, _dir_atr) - _e.gravedad_enemigo;
                _e.estado = EnemyState.AIRBORNE;
            }
        break;

        case GanchoEnemigo.ARRASTRANDO:
            ge_punta_x = _c[0];
            ge_punta_y = _c[1];
            var _dir_m = point_direction(_o[0], _o[1], mouse_x, mouse_y);

            if (!mouse_check_button(mb_right) || ge_timer > ge_arrastre_max)
            {
                // Lanzamiento hacia la mira (recibir_impacto marca la estampada si va hacia abajo)
                var _lx = lengthdir_x(ge_vel_lanzar, _dir_m);
                var _ly = lengthdir_y(ge_vel_lanzar, _dir_m);
                var _dl = ge_danio_lanzar;
                var _sl = ge_stagger;
                with (_e) recibir_impacto(_dl, _lx, _ly, _sl);
                if (instance_exists(_e)) array_push(ge_proyectiles, { e: _e, t: 60, golpeados: [] });
                with (obj_controladores) aplicar_hitstop(3);
                mec_gancho_enemigo_terminar();
            }
            else
            {
                // Cuelga del cable: va hacia el punto a ge_radio_arrastre en dirección a la mira
                var _px = _o[0] + lengthdir_x(ge_radio_arrastre, _dir_m);
                var _py = _o[1] + lengthdir_y(ge_radio_arrastre, _dir_m);
                var _vm = ge_vel_arrastre_max;
                _e.hsp = clamp((_px - _c[0]) * ge_seguir, -_vm, _vm);
                _e.vsp = clamp((_py - _c[1]) * ge_seguir, -_vm, _vm) - _e.gravedad_enemigo;
                _e.estado = EnemyState.AIRBORNE;
                _e.aturdido_timer = max(_e.aturdido_timer, 10);
            }
        break;

        case GanchoEnemigo.YENDO:
            // El jugador viaja hacia el enemigo: se descarta lo que obj_jugador movió este frame
            ge_punta_x = _c[0];
            ge_punta_y = _c[1];
            _j.x = x_inicio;
            _j.y = y_inicio;
            _j.hsp = 0;
            _j.vsp = 0;
            var _o2 = mec_gancho_origen(_j);
            var _d_ir = point_distance(_o2[0], _o2[1], _c[0], _c[1]);
            var _paso = min(ge_vel_ir, max(0, _d_ir - ge_distancia_final));
            var _dir_ir = point_direction(_o2[0], _o2[1], _c[0], _c[1]);
            var _choque = mec_mover_con_choque(_j, lengthdir_x(_paso, _dir_ir), lengthdir_y(_paso, _dir_ir));

            if (_paso <= 0 || (_choque[0] && _choque[1]) || ge_timer > ge_duracion_max)
            {
                _j.vsp = -4;                    // pequeño salto al llegar, para golpear en el aire
                dash_aire_disponible = true;    // llegar recarga el dash aéreo
                mirando = (_e.x >= _j.x) ? 1 : -1;
                mec_gancho_enemigo_terminar();
            }
        break;
    }
}

// Draw: anillo sobre el enemigo apuntado y cable mientras está activo
function mec_gancho_enemigo_dibujar()
{
    if (ge_estado == GanchoEnemigo.INACTIVO)
    {
        if (instance_exists(ge_objetivo_mira))
        {
            var _cm = mec_gancho_enemigo_centro(ge_objetivo_mira);
            var _r = max(ge_objetivo_mira.bbox_right - ge_objetivo_mira.bbox_left, ge_objetivo_mira.bbox_bottom - ge_objetivo_mira.bbox_top) / 2 + 6;
            draw_set_color(make_color_rgb(255, 60, 200));
            draw_set_alpha(0.6 + 0.4 * abs(sin(current_time / 150)));
            draw_circle(_cm[0], _cm[1], _r, true);
            draw_circle(_cm[0], _cm[1], _r + 1, true);
            draw_set_alpha(1);
            draw_set_color(c_white);
        }
        return;
    }

    var _o = mec_animacion_mano_gancho();
    mec_animacion_dibujar_cable(_o[0], _o[1], ge_punta_x, ge_punta_y, ge_estado != GanchoEnemigo.LANZANDO, 0);
}
