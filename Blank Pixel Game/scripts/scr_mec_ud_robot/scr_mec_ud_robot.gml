// ==============================
// ULTIMATE DEL UNDERDOG: MINI ROBOT (F). Contexto: obj_mecanicas_jugador.
// El jugador se sube a un mini robot de puños enormes durante máx. 20 s (lo que dure la barra).
// F lo activa (con al menos ub_min_activar de barra) y F otra vez lo cancela; la barra que
// sobra se puede volver a usar. La barra se carga con el daño hecho en estilo Underdog y baja
// mientras el robot está activo.
//
//   Click al lado ............ Robo-puñetazo
//   W + click en el suelo .... Robo-uppercut: lanza alto al enemigo (y el robot salta con él)
//   W + click en el aire ..... Uppercut aéreo: lo eleva poquito para seguir el combo
//   S + click en el aire ..... Martillo: lo estampa contra el suelo y rebota (el robot no cae)
//
// Dentro del robot recibe ub_reduccion menos de daño y no se aturde (súper armadura).
// No modifica obj_jugador: reemplaza su variable recibir_impacto en tiempo de ejecución
// y la restaura al bajarse.
// ==============================

function mec_ud_robot_crear()
{
    mec_ult_carga();                // la barra es la general compartida (scr_mec_comun)
    ub_max = ULT_MAX;                   // daño necesario para llenar la barra
    ub_duracion = 20 * 60;          // frames que dura la barra llena (20 s a 60 FPS)
    ub_min_activar = 20;            // barra mínima para (re)activarlo
    ub_reduccion = 0.75;            // 75 % menos de daño
    ub_reduccion_empuje = 0.7;      // y 70 % menos de empuje

    ub_activo = false;
    ub_ctx = undefined;             // recibir_impacto original del jugador
    ub_flash = 0;                   // destello al subirse / bajarse
    ub_t = 0;

    // Martillo: el enemigo estampado rebota un poco al tocar el suelo
    ub_rebote_vsp = -6;
    ub_rebotes = [];                // [{e, t}]

    ub_particulas = [];             // vapor: [{x, y, vx, vy, t}]

    // Sprites (opcionales: si aún no existen se usan los del Underdog)
    ub_spr_idle = asset_get_index("spr" + "_jugador_ud_robot_idle");
    ub_spr_correr = asset_get_index("spr" + "_jugador_ud_robot_correr");
    ub_spr_salto = asset_get_index("spr" + "_jugador_ud_robot_salto");
    ub_spr_puno = asset_get_index("spr" + "_jugador_ud_robot_puno");
    ub_spr_upper = asset_get_index("spr" + "_jugador_ud_robot_upper");
    ub_spr_elevar = asset_get_index("spr" + "_jugador_ud_robot_elevar");
    ub_spr_martillo = asset_get_index("spr" + "_jugador_ud_robot_martillo");
}

function mec_ud_robot_lista()
{
    return mec_underdog_activo() && !ub_activo && mec_ult_carga() >= ub_min_activar;
}

// Suma a la barra el daño hecho en estilo Underdog (no carga mientras el robot está activo)
function mec_ud_robot_cargar(_cantidad)
{
    if (!ub_activo) mec_ult_cargar(_cantidad);      // barra general: carga en cualquier estilo
}

function mec_ud_robot_vapor(_x, _y, _n, _fuerza)
{
    repeat (_n)
    {
        array_push(ub_particulas, { x: _x + random_range(-14, 14), y: _y - random_range(0, 40),
            vx: random_range(-2, 2) * _fuerza, vy: -random_range(0.5, 2.5) * _fuerza, t: irandom_range(16, 28) });
    }
}

function mec_ud_robot_activar()
{
    var _j = jugador;
    ub_activo = true;
    ub_flash = 12;

    // Daño reducido y súper armadura: envuelve recibir_impacto del jugador
    ub_ctx = { orig: _j.recibir_impacto, j: _j, reduccion: ub_reduccion, empuje: 1 - ub_reduccion_empuje };
    _j.recibir_impacto = method(ub_ctx, function(_damage, _kx, _ky, _stagger)
    {
        var _estado = j.estado;
        orig(_damage * (1 - reduccion), _kx * empuje, _ky * empuje, _stagger * (1 - reduccion));
        if (instance_exists(j))
        {
            j.estado = _estado;             // no lo saca de lo que estaba haciendo
            j.stagger_timer = 0;
        }
    });

    mec_ud_robot_vapor(_j.x, _j.y, 24, 1.6);
    mec_underdog_particulas(_j.x, _j.y, 12, 1.2);
    instance_create_layer(_j.x, _j.y, "Instances", obj_fx_estampada, { fuerza: 0.5, radio: 70 });
    with (obj_controladores) aplicar_hitstop(8);
    with (obj_camara) aplicar_temblor(6, 16);
    with (obj_mec_golpe) { golpe_nombre = "ROBOT!"; golpe_nombre_timer = 60; }
}

function mec_ud_robot_desactivar()
{
    if (!ub_activo) return;
    ub_activo = false;
    ub_flash = 8;

    var _j = jugador;
    if (_j != noone && instance_exists(_j))
    {
        if (is_struct(ub_ctx)) _j.recibir_impacto = ub_ctx.orig;
        mec_ud_robot_vapor(_j.x, _j.y, 18, 1.2);
    }
    ub_ctx = undefined;
}

// Begin Step: ANTES de mec_underdog_inicio (con el robot activo el Underdog no excava ni taladra)
function mec_ud_robot_inicio()
{
    var _j = jugador;
    ub_t++;
    ub_flash = max(0, ub_flash - 1);

    if (ub_activo && !mec_underdog_activo())
    {
        mec_ud_robot_desactivar();      // cambiar de estilo lo baja del robot
        return;
    }

    if (keyboard_check_pressed(ord("F")) && mec_underdog_activo())
    {
        if (ub_activo) mec_ud_robot_desactivar();
        else if (mec_ud_robot_lista() && !ud_bajo_tierra && ud_accion == UdAccion.NINGUNA) mec_ud_robot_activar();
    }

    if (!ub_activo) return;

    // La barra baja mientras se usa
    mec_ult_set(mec_ult_carga() - ub_max / ub_duracion);
    if (mec_ult_carga() <= 0)
    {
        mec_ud_robot_desactivar();
        return;
    }

    gancho_cooldown = max(gancho_cooldown, 2);      // el robot no usa el gancho
    if (ub_t mod 10 == 0) mec_ud_robot_vapor(_j.x - mirando * 12, _j.y - 30, 1, 0.6);
}

// End Step: rebote de los enemigos estampados por el martillo y partículas de vapor
function mec_ud_robot_fin()
{
    for (var i = array_length(ub_rebotes) - 1; i >= 0; i--)
    {
        var _r = ub_rebotes[i];
        _r.t--;
        var _e = _r.e;
        if (!instance_exists(_e) || _r.t <= 0)
        {
            array_delete(ub_rebotes, i, 1);
            continue;
        }
        // Tocó el suelo (dejó de estar estampado y quedó derribado): rebota un poco
        if (!_e.estampado && _e.estado == EnemyState.KNOCKED_DOWN)
        {
            _e.vsp = ub_rebote_vsp;
            mec_underdog_particulas(_e.x, _e.y, 8, 1);
            array_delete(ub_rebotes, i, 1);
        }
    }

    for (var i = array_length(ub_particulas) - 1; i >= 0; i--)
    {
        var _p = ub_particulas[i];
        _p.x += _p.vx;
        _p.y += _p.vy;
        _p.vx *= 0.92;
        _p.t--;
        if (_p.t <= 0) array_delete(ub_particulas, i, 1);
    }
}

// Lo llama obj_hitbox_golpe cuando un golpe del jugador conecta
function mec_ud_robot_al_golpear(_target, _damage)
{
    // (la carga de la barra ya la hace obj_hitbox_golpe con mec_swordmaster_ultimate_cargar)
    if (!ub_activo || !instance_exists(_target)) return;

    var _g = undefined;
    with (obj_mec_golpe) _g = golpe_actual;
    if (is_struct(_g) && variable_struct_exists(_g, "rebote") && _g.rebote
        && variable_instance_exists(_target, "estampado"))
    {
        array_push(ub_rebotes, { e: _target, t: 90 });
    }
    mec_ud_robot_vapor(_target.x, _target.y, 4, 1);
}

// Golpe del click con el robot (contexto: obj_mec_golpe). zona: [adelante desde, hasta, arriba, abajo]
function mec_ud_robot_elegir_golpe(_j)
{
    var _suelo = mec_en_suelo(_j);
    var _w = keyboard_check(ord("W"));
    var _s = keyboard_check(ord("S"));

    if (_suelo && _w)
        return { nombre: "Robo-uppercut", danio: 12, kx: 0, ky: -13, stagger: 45, hitstop: 8, jugador_vsp: -13,
                 zona: [-8, 50, -110, 0] };
    if (!_suelo && _w)
        return { nombre: "Uppercut aereo", danio: 8, kx: 0, ky: -6, stagger: 30, hitstop: 5, jugador_vsp: -5,
                 zona: [-10, 48, -100, 4] };
    if (!_suelo && _s)
        return { nombre: "Martillo", danio: 12, kx: 0, ky: 16, stagger: 45, hitstop: 8, jugador_vsp: undefined,
                 zona: [-16, 46, -40, 60], rebote: true };
    return { nombre: "Robo-punetazo", danio: 10, kx: 6, ky: -1, stagger: 25, hitstop: 6,
             jugador_vsp: _suelo ? undefined : -2, zona: [-4, 60, -64, -8] };
}

// Sprite del robot (contexto: obj_mecanicas_jugador, lo usa mec_animacion_fin).
// Devuelve [sprite, image_speed, cuadro fijo (-1 = libre)] o undefined si falta el sprite.
function mec_ud_robot_sprite(_spr_base, _es_golpe, _nombre_golpe, _vsp)
{
    if (_es_golpe)
    {
        var _sg = ub_spr_puno;
        if (_nombre_golpe == "Robo-uppercut") _sg = ub_spr_upper;
        else if (_nombre_golpe == "Uppercut aereo") _sg = ub_spr_elevar;
        else if (_nombre_golpe == "Martillo") _sg = ub_spr_martillo;
        return (_sg != -1) ? [_sg, 0, -1] : undefined;      // el cuadro sigue el avance del golpe
    }
    if (_spr_base == spr_jugador_correr && ub_spr_correr != -1) return [ub_spr_correr, 1, -1];
    if (_spr_base == spr_jugador_dash && ub_spr_correr != -1) return [ub_spr_correr, 0, 1];
    if (_spr_base == spr_jugador_salto && ub_spr_salto != -1) return [ub_spr_salto, 0, (_vsp < 0) ? 0 : 1];
    if (ub_spr_idle != -1) return [ub_spr_idle, 1, -1];
    return undefined;
}

// Draw: vapor y destello al subirse
function mec_ud_robot_dibujar()
{
    var _j = jugador;
    for (var i = 0; i < array_length(ub_particulas); i++)
    {
        var _p = ub_particulas[i];
        draw_set_alpha(min(0.7, _p.t / 20));
        draw_set_color(make_color_rgb(200, 205, 215));
        draw_circle(_p.x, _p.y, 2 + (28 - _p.t) / 8, false);
    }
    draw_set_alpha(1);

    if (ub_flash > 0 && instance_exists(_j))
    {
        gpu_set_blendmode(bm_add);
        draw_set_color(make_color_rgb(255, 150, 40));
        draw_set_alpha(ub_flash / 12 * 0.8);
        draw_circle(_j.x, _j.y - 36, 20 + (12 - ub_flash) * 4, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }
    draw_set_color(c_white);
}

// Draw GUI: barra de la ultimate (solo en Underdog), donde va la del Swordmaster
function mec_ud_robot_dibujar_gui()
{
    if (!mec_underdog_activo()) return;

    var _gw = display_get_gui_width();
    var _ancho = 180;
    var _x2 = _gw - 16;
    var _x1 = _x2 - _ancho;
    var _y = 78;
    var _lista = mec_ud_robot_lista();
    var _llena = mec_ult_carga() >= ub_max;

    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(_x1, _y, _x2, _y + 8, false);
    // Marca del mínimo para activarlo
    draw_set_alpha(1);
    draw_set_color(c_dkgray);
    var _xm = _x1 + _ancho * ub_min_activar / ub_max;
    draw_line(_xm, _y, _xm, _y + 8);

    draw_set_alpha((_llena && !ub_activo) ? 0.7 + 0.3 * abs(sin(current_time / 120)) : 1);
    draw_set_color(ub_activo ? make_color_rgb(255, 150, 40) : (_lista ? c_white : make_color_rgb(255, 190, 90)));
    draw_rectangle(_x1, _y, _x1 + _ancho * mec_ult_carga() / ub_max, _y + 8, false);
    draw_set_alpha(1);

    draw_set_halign(fa_right);
    draw_set_color(ub_activo ? make_color_rgb(255, 190, 90) : (_lista ? c_white : c_ltgray));
    var _txt = "Robot";
    if (ub_activo) _txt = "ROBOT " + string_format(mec_ult_carga() / ub_max * ub_duracion / 60, 1, 1) + " s (F: bajarse)";
    else if (_lista) _txt = "ROBOT LISTO: F";
    draw_text(_x2, _y + 12, _txt);
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}
