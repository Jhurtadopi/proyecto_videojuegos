// ==============================
// ESTILO SHIELD (escudo de sierra). Contexto: obj_mecanicas_jugador.
//   E (mantener) = guardia. Los primeros frames son PARRY:
//       perfecto (destello naranja): aturde al atacante y no gasta guardia
//       tardío   (destello amarillo): aturde poco y gasta guardia
//     Después bloquea: cada golpe gasta guardia y al agotarla se rompe (aturdido un rato).
//     Los proyectiles no se parrean: el escudo los absorbe (gastan guardia según su daño).
//   Shift = ESTAMPIDA: carga con el escudo hacia el enemigo más cercano en la dirección
//           en que mira y lo desestabiliza (lo saca del combo).
//   Q = lanzar el escudo de sierra al enemigo más cercano: se queda clavado, lo aturde y le
//       hace daño poco a poco; luego vuelve. Q otra vez lo hace volver antes.
//   Click = escudazo (sin escudo: puñetazo).
//
// El bloqueo cuerpo a cuerpo usa el sistema de obj_hitbox (variables bloqueando, mirando,
// bloqueo_* del objetivo, hecho para obj_enemigo_boss): aquí solo se escriben esas variables
// en el jugador. No se modifican obj_jugador ni obj_hitbox.
// ==============================

function mec_shield_crear()
{
    sh_tiene_escudo = true;
    sh_escudo_inst = noone;         // obj_escudo_lanzado en vuelo
    sh_t = 0;

    // Guardia y parry (E)
    sh_guardia = false;
    sh_guardia_t = 0;               // frames desde que se levantó el escudo
    sh_parry_perfecto = 6;          // frames de parry perfecto (naranja)
    sh_parry_ventana = 14;          // hasta aquí es parry tardío (amarillo); después, bloqueo normal
    sh_resistencia = 4;             // golpes que aguanta la guardia antes de romperse
    sh_recuperacion = 50;           // frames aturdido tras romperse la guardia
    sh_golpes_prev = 0;
    sh_recovery_prev = 0;
    sh_parry_stagger_perfecto = 75;
    sh_parry_stagger_tardio = 25;
    sh_alcance_parry = 90;          // px para encontrar al atacante que se aturde

    // Estampida (Shift)
    sh_est_timer = 0;
    sh_est_dur = 20;
    sh_est_vel = 12;
    sh_est_alcance = 320;           // px máximos para elegir objetivo
    sh_est_cooldown = 0;
    sh_est_cooldown_max = 35;
    sh_est_objetivo = noone;
    sh_est_danio = 6;
    sh_est_kx = 9;
    sh_est_ky = -4;
    sh_est_stagger = 70;            // desestabiliza: lo saca del combo

    // Lanzamiento (Q)
    sh_lanzar_alcance = 420;
    sh_lanzar_anim = 0;             // frames de la pose de lanzar

    // Efectos
    sh_chispas = [];                // [{x, y, ang, largo, t, tmax, color}]
    sh_destello = 0;
    sh_destello_color = c_white;
    sh_destello_x = 0;
    sh_destello_y = 0;

    // Sprites opcionales (existen después de procesar las hojas del Shield)
    sh_spr_idle = asset_get_index("spr" + "_jugador_sh_idle");
    sh_spr_correr = asset_get_index("spr" + "_jugador_sh_correr");
    sh_spr_dash = asset_get_index("spr" + "_jugador_sh_dash");
    sh_spr_parry = asset_get_index("spr" + "_jugador_sh_parry");
    sh_spr_lanzar = asset_get_index("spr" + "_jugador_sh_lanzar");
    sh_spr_sin_idle = asset_get_index("spr" + "_jugador_sh_sin_idle");
    sh_spr_sin_correr = asset_get_index("spr" + "_jugador_sh_sin_correr");
}

function mec_shield_activo()
{
    return global.estilo == Estilo.SHIELD;
}

// Variables del sistema de bloqueo de obj_hitbox en el jugador (se crean si no existen)
function mec_shield_preparar_jugador(_j)
{
    if (!variable_instance_exists(_j, "bloqueando"))
    {
        _j.bloqueando = false;
        _j.bloqueo_golpes_recibidos = 0;
        _j.bloqueo_resistencia = sh_resistencia;
        _j.bloqueo_recovery = sh_recuperacion;
        _j.bloqueo_recovery_timer = 0;
    }
    _j.mirando = mirando;           // obj_hitbox solo bloquea golpes de frente
}

function mec_shield_chispas(_x, _y, _color, _n, _largo)
{
    repeat (_n)
    {
        var _tm = irandom_range(8, 14);
        array_push(sh_chispas, { x: _x, y: _y, ang: random(360), largo: random_range(_largo * 0.5, _largo), t: _tm, tmax: _tm, color: _color });
    }
}

function mec_shield_destello(_x, _y, _color)
{
    sh_destello = 10;
    sh_destello_color = _color;
    sh_destello_x = _x;
    sh_destello_y = _y;
}

// Enemigo más cercano en la dirección _dir (o en cualquiera si _dir == 0), a menos de _alcance
function mec_shield_buscar(_dir, _alcance)
{
    var _j = jugador;
    var _mejor = noone;
    var _dmin = _alcance;
    with (obj_enemigo)
    {
        if (!visible) continue;
        var _dx = x - _j.x;
        if ((_dir == 0 || sign(_dx) == _dir) && abs(y - _j.y) <= 96)
        {
            var _d = point_distance(x, y, _j.x, _j.y);
            if (_d < _dmin) { _dmin = _d; _mejor = id; }
        }
    }
    return _mejor;
}

// Proyectiles enemigos que llegan de frente: el escudo los absorbe antes de que choquen
function mec_shield_absorber_proyectiles(_j)
{
    var _x1 = (mirando == 1) ? _j.x - 4 : _j.x - 60;
    var _x2 = (mirando == 1) ? _j.x + 60 : _j.x + 4;
    var _lista = ds_list_create();
    var _n = collision_rectangle_list(_x1, _j.y - 70, _x2, _j.y, obj_proyectil, false, true, _lista, false);
    for (var i = 0; i < _n; i++)
    {
        var _p = _lista[| i];
        if (_p.equipo != "enemigo" || sign(_p.vx) == mirando) continue;    // solo los que vienen de frente

        var _perfecto = sh_guardia_t < sh_parry_perfecto;
        var _costo = (_p.damage >= 15) ? 2 : 1;
        if (!_perfecto) _j.bloqueo_golpes_recibidos += _costo;
        sh_golpes_prev = _j.bloqueo_golpes_recibidos;

        var _col = _perfecto ? make_color_rgb(255, 140, 0) : make_color_rgb(150, 220, 255);
        mec_shield_chispas(_p.x, _p.y, _col, 6, 10);
        instance_destroy(_p);
    }
    ds_list_destroy(_lista);

    if (_j.bloqueo_golpes_recibidos >= _j.bloqueo_resistencia) mec_shield_romper_guardia(_j);
}

function mec_shield_romper_guardia(_j)
{
    _j.bloqueando = false;
    _j.bloqueo_golpes_recibidos = 0;
    _j.bloqueo_recovery_timer = sh_recuperacion;
    sh_guardia = false;
    mec_shield_chispas(_j.x + mirando * 16, _j.y - 36, make_color_rgb(200, 60, 60), 10, 16);
    with (obj_camara) aplicar_temblor(4, 12);
}

// Reacción a un golpe bloqueado durante la ventana de parry: 2 perfecto, 1 tardío
function mec_shield_parry(_j, _tipo)
{
    var _px = _j.x + mirando * 18;
    var _py = _j.y - 38;
    var _atacante = mec_shield_buscar(mirando, sh_alcance_parry);

    if (_tipo == 2)
    {
        var _naranja = make_color_rgb(255, 140, 0);
        mec_shield_chispas(_px, _py, _naranja, 16, 26);
        mec_shield_destello(_px, _py, _naranja);
        _j.bloqueo_golpes_recibidos = max(0, _j.bloqueo_golpes_recibidos - 1);   // el perfecto no gasta guardia
        var _st = sh_parry_stagger_perfecto;
        var _kx = mirando * 4;
        if (_atacante != noone) with (_atacante) recibir_impacto(0, _kx, -2, _st);
        with (obj_controladores) aplicar_hitstop(8);
        with (obj_camara) aplicar_temblor(5, 12);
    }
    else
    {
        var _amarillo = make_color_rgb(255, 230, 60);
        mec_shield_chispas(_px, _py, _amarillo, 9, 18);
        mec_shield_destello(_px, _py, _amarillo);
        var _st2 = sh_parry_stagger_tardio;
        if (_atacante != noone) with (_atacante) recibir_impacto(0, 0, 0, _st2);
        with (obj_controladores) aplicar_hitstop(4);
        with (obj_camara) aplicar_temblor(2, 6);
    }
}

// Begin Step: ANTES del dash normal (lo reemplaza por la estampida)
function mec_shield_inicio()
{
    var _j = jugador;
    sh_t++;
    sh_est_cooldown = max(0, sh_est_cooldown - 1);
    mec_shield_preparar_jugador(_j);
    if (_j.bloqueo_recovery_timer > 0) _j.bloqueo_recovery_timer--;   // nadie más lo descuenta en el jugador

    if (!mec_shield_activo())
    {
        _j.bloqueando = false;
        sh_guardia = false;
        sh_est_timer = 0;
        return;
    }

    // Guardia (E): solo con el escudo en la mano y sin la guardia rota
    var _puede = sh_tiene_escudo && _j.bloqueo_recovery_timer <= 0 && sh_est_timer == 0 && !mec_gancho_activo();
    if (_puede && keyboard_check(ord("E")))
    {
        if (!sh_guardia)
        {
            sh_guardia = true;
            sh_guardia_t = 0;
            sh_golpes_prev = _j.bloqueo_golpes_recibidos;
        }
        else sh_guardia_t++;
    }
    else
    {
        if (sh_guardia) _j.bloqueo_golpes_recibidos = 0;    // bajar el escudo recupera la guardia
        sh_guardia = false;
    }
    _j.bloqueando = sh_guardia;
    sh_recovery_prev = _j.bloqueo_recovery_timer;

    if (sh_guardia) mec_shield_absorber_proyectiles(_j);

    // Estampida (Shift) reemplaza al dash normal mientras el escudo está en la mano
    if (sh_tiene_escudo)
    {
        dash_cooldown = max(dash_cooldown, 2);
        if (keyboard_check_pressed(vk_shift) && sh_est_timer == 0 && sh_est_cooldown == 0 && !sh_guardia && !mec_gancho_activo())
        {
            sh_est_objetivo = mec_shield_buscar(mirando, sh_est_alcance);
            sh_est_timer = sh_est_dur;
            sh_est_cooldown = sh_est_cooldown_max;
        }
    }
    if (sh_est_timer > 0) _j.vsp = -_j.gravedad;    // carga a ras de suelo, sin caer

    // Lanzar el escudo (Q) / hacerlo volver
    if (keyboard_check_pressed(ord("Q")))
    {
        if (sh_tiene_escudo && !sh_guardia && sh_est_timer == 0)
        {
            var _obj = mec_shield_buscar(mirando, sh_lanzar_alcance);
            if (_obj == noone) _obj = mec_shield_buscar(0, sh_lanzar_alcance);
            sh_escudo_inst = instance_create_layer(_j.x + mirando * 16, _j.y - 40, "Instances", obj_escudo_lanzado,
                { dueno: id, objetivo: _obj, dir: mirando });
            sh_tiene_escudo = false;
            sh_lanzar_anim = 12;
        }
        else if (instance_exists(sh_escudo_inst))
        {
            sh_escudo_inst.estado = 2;      // vuelve
        }
    }
}

// End Step
function mec_shield_fin()
{
    var _j = jugador;
    sh_lanzar_anim = max(0, sh_lanzar_anim - 1);
    sh_destello = max(0, sh_destello - 1);

    for (var i = array_length(sh_chispas) - 1; i >= 0; i--)
    {
        sh_chispas[i].t--;
        if (sh_chispas[i].t <= 0) array_delete(sh_chispas, i, 1);
    }

    // Seguro: si el escudo desapareció sin volver, se recupera
    if (!sh_tiene_escudo && !instance_exists(sh_escudo_inst)) sh_tiene_escudo = true;

    if (!mec_shield_activo()) return;

    // ¿El sistema de bloqueo de obj_hitbox bloqueó o rompió la guardia este frame?
    if (_j.bloqueo_recovery_timer > sh_recovery_prev)
    {
        mec_shield_romper_guardia(_j);
    }
    else if (sh_guardia && _j.bloqueo_golpes_recibidos > sh_golpes_prev)
    {
        if (sh_guardia_t < sh_parry_perfecto) mec_shield_parry(_j, 2);
        else if (sh_guardia_t < sh_parry_ventana) mec_shield_parry(_j, 1);
        else mec_shield_chispas(_j.x + mirando * 18, _j.y - 38, make_color_rgb(150, 220, 255), 5, 10);  // bloqueo normal
        sh_golpes_prev = _j.bloqueo_golpes_recibidos;
    }

    // Estampida: carga horizontal hasta chocar con un enemigo
    if (sh_est_timer > 0)
    {
        sh_est_timer--;
        var _dir = mirando;
        var _golpeado = collision_rectangle(_j.x + _dir * 6, _j.y - 56, _j.x + _dir * 34, _j.y - 4, obj_enemigo, false, true);
        if (_golpeado != noone && _golpeado.visible)
        {
            var _d = sh_est_danio;
            var _kx = _dir * sh_est_kx;
            var _ky = sh_est_ky;
            var _st = sh_est_stagger;
            with (_golpeado) recibir_impacto(_d, _kx, _ky, _st);
            mec_shield_chispas(_j.x + _dir * 24, _j.y - 36, c_white, 10, 18);
            with (obj_controladores) aplicar_hitstop(6);
            with (obj_camara) aplicar_temblor(5, 12);
            sh_est_timer = 0;
        }
        else
        {
            mec_mover_hasta_x(_j, x_inicio + _dir * sh_est_vel);
            if (abs(_j.x - x_inicio) < 1) sh_est_timer = 0;      // chocó con una pared
        }
        _j.vsp = 0;
    }
}

// Draw: chispas del parry, destello, aura de guardia y líneas de la estampida
function mec_shield_dibujar()
{
    var _j = jugador;
    if (!instance_exists(_j)) return;

    gpu_set_blendmode(bm_add);

    // Aura frente al escudo mientras está en guardia (más intensa en la ventana de parry)
    if (sh_guardia && mec_shield_activo())
    {
        var _a = (sh_guardia_t < sh_parry_ventana) ? 0.6 : 0.3;
        draw_set_color(make_color_rgb(80, 200, 255));
        draw_set_alpha(_a);
        var _cx = _j.x + mirando * 20;
        var _cy = _j.y - 38;
        for (var k = -2; k <= 2; k++)
        {
            var _ang = ((mirando == 1) ? 0 : 180) + k * 18;
            draw_line_width(_cx + lengthdir_x(14, _ang), _cy + lengthdir_y(14, _ang),
                            _cx + lengthdir_x(14, _ang + 18), _cy + lengthdir_y(14, _ang + 18), 2);
        }
    }

    // Líneas de velocidad de la estampida
    if (sh_est_timer > 0)
    {
        draw_set_color(c_white);
        draw_set_alpha(0.5);
        repeat (4)
        {
            var _ly = _j.y - irandom_range(10, 56);
            var _lx = _j.x - mirando * irandom_range(10, 30);
            draw_line(_lx, _ly, _lx - mirando * irandom_range(12, 28), _ly);
        }
    }

    // Destello del parry (círculo que se abre)
    if (sh_destello > 0)
    {
        draw_set_color(sh_destello_color);
        draw_set_alpha(sh_destello / 10);
        draw_circle(sh_destello_x, sh_destello_y, 4 + (10 - sh_destello) * 2.5, false);
        draw_set_alpha(sh_destello / 14);
        draw_circle(sh_destello_x, sh_destello_y, 10 + (10 - sh_destello) * 4, true);
    }

    // Chispas (líneas radiales que se alejan, como el parry de Sekiro)
    for (var i = 0; i < array_length(sh_chispas); i++)
    {
        var _c = sh_chispas[i];
        var _p = 1 - _c.t / _c.tmax;
        var _r1 = 4 + _c.largo * _p;
        var _r2 = _r1 + _c.largo * 0.5 * (1 - _p);
        draw_set_color(_c.color);
        draw_set_alpha(_c.t / _c.tmax);
        draw_line_width(_c.x + lengthdir_x(_r1, _c.ang), _c.y + lengthdir_y(_r1, _c.ang),
                        _c.x + lengthdir_x(_r2, _c.ang), _c.y + lengthdir_y(_r2, _c.ang), 2);
    }

    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// Golpe del click en Shield (lo usa obj_mec_golpe). Contexto: obj_mec_golpe.
function mec_shield_elegir_golpe(_j)
{
    var _con = true;
    with (obj_mecanicas_jugador) _con = sh_tiene_escudo;
    if (_con) return { nombre: "Escudazo", danio: 8, kx: 7, ky: -2, stagger: 35, hitstop: 5, jugador_vsp: undefined, zona: [-6, 42, -58, -6] };
    return { nombre: "Golpe sin escudo", danio: 4, kx: 3, ky: 0, stagger: 12, hitstop: 3, jugador_vsp: undefined, zona: [-6, 34, -54, -14] };
}
