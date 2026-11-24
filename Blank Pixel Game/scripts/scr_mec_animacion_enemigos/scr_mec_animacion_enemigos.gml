// ==============================
// ANIMACIÓN DE LOS ENEMIGOS. Contexto: obj_mecanicas_jugador (corre en su End Step).
// Los objetos de enemigos son de otros colaboradores: aquí NO se modifica su código, solo se
// escriben variables en tiempo de ejecución (sprite_index, image_index, mask_index...) según
// su estado. La máscara de colisión se queda fija en su sprite original (spr_enemigo /
// spr_torreta) para que los sprites nuevos, más grandes, no cambien cómo chocan con el suelo.
//
//   obj_enemigo_ligero / mediano / pesado -> sprites spr_enemigo_ligero_*
//   obj_enemigo_boss                      -> spr_enemigo_jefe_*
//   obj_torreta (centinela)               -> spr_enemigo_centinela_*  (y sus balas, obj_proyectil)
//
// Si un sprite todavía no existe, ese enemigo se sigue viendo como antes.
// ==============================

function mec_enemigos_anim_crear()
{
    ea_t = 0;       // reloj de las animaciones (se congela en el hitstop)

    ea_ligero = {
        idle: asset_get_index("spr" + "_enemigo_ligero_idle"),
        correr: asset_get_index("spr" + "_enemigo_ligero_correr"),
        ataque: asset_get_index("spr" + "_enemigo_ligero_ataque"),
        disparo: -1,
        guardia: -1,
        aire: asset_get_index("spr" + "_enemigo_ligero_aire"),
        aturdido: asset_get_index("spr" + "_enemigo_ligero_aturdido"),
        derribado: asset_get_index("spr" + "_enemigo_ligero_derribado"),
        ataque_frames: 18,
    };
    ea_jefe = {
        idle: asset_get_index("spr" + "_enemigo_jefe_idle"),
        correr: asset_get_index("spr" + "_enemigo_jefe_caminar"),
        ataque: asset_get_index("spr" + "_enemigo_jefe_ataque"),
        disparo: asset_get_index("spr" + "_enemigo_jefe_disparo"),
        guardia: asset_get_index("spr" + "_enemigo_jefe_guardia"),
        aire: asset_get_index("spr" + "_enemigo_jefe_aire"),
        aturdido: asset_get_index("spr" + "_enemigo_jefe_aturdido"),
        derribado: asset_get_index("spr" + "_enemigo_jefe_derribado"),
        ataque_frames: 26,
    };
    ea_centinela = {
        idle: asset_get_index("spr" + "_enemigo_centinela_idle"),
        disparo: asset_get_index("spr" + "_enemigo_centinela_disparo"),    // 0 carga, 1 disparo, 2 recuperación
        aturdida: asset_get_index("spr" + "_enemigo_centinela_aturdida"),
        bala: asset_get_index("spr" + "_enemigo_centinela_bala"),
    };

    // La bala tiene la estela a la izquierda: su centro de giro es la esfera (punta derecha)
    var _b = ea_centinela.bala;
    if (_b != -1) sprite_set_offset(_b, sprite_get_width(_b) - 3, sprite_get_height(_b) div 2);

    // Hurtbox del jefe del tamaño de su sprite nuevo (el original es de 32x48)
    ea_jefe_hurtbox = [44, 88];
}

// Cuadro de una animación en bucle: cambia cada _cada frames
function mec_enemigos_bucle(_spr, _cada)
{
    return (ea_t div _cada) mod max(1, sprite_get_number(_spr));
}

function mec_enemigos_animacion()
{
    var _congelado = variable_global_exists("hitstop_timer") && global.hitstop_timer > 0;
    if (!_congelado) ea_t++;

    var _t = ea_t;
    var _jug = jugador;
    var _L = ea_ligero;
    var _B = ea_jefe;
    var _C = ea_centinela;
    var _hb = ea_jefe_hurtbox;

    with (obj_enemigo)
    {
        var _set = undefined;
        var _tipo = 0;                  // 1 soldado, 2 jefe, 3 centinela
        if (object_index == obj_enemigo_boss) { _set = _B; _tipo = 2; }
        else if (object_index == obj_torreta) { _set = _C; _tipo = 3; }
        else if (object_index == obj_enemigo_ligero || object_index == obj_enemigo_mediano
              || object_index == obj_enemigo_pesado) { _set = _L; _tipo = 1; }
        if (is_undefined(_set) || _set.idle == -1) continue;

        // Primera vez: guarda la máscara original y prepara los contadores propios
        if (!variable_instance_exists(id, "ea_mascara"))
        {
            ea_mascara = sprite_index;
            ea_prev_x = x;
            ea_ataque_t = 0;
            ea_ataque_prev = false;
            ea_disparo_t = 0;
            ea_disparo_prev = variable_instance_exists(id, "disparo_timer") ? disparo_timer : 0;
            if (_tipo == 2 && variable_instance_exists(id, "hurtbox") && instance_exists(hurtbox))
            {
                hurtbox.image_xscale = _hb[0] / 32;
                hurtbox.image_yscale = _hb[1] / 64;
            }
        }
        mask_index = ea_mascara;
        image_speed = 0;

        var _mov = abs(x - ea_prev_x) > 0.3;
        if (!_congelado)
        {
            ea_prev_x = x;
            ea_ataque_t = max(0, ea_ataque_t - 1);
            ea_disparo_t = max(0, ea_disparo_t - 1);
        }

        // El ataque cuerpo a cuerpo dura muy pocos frames: se muestra completo con un contador propio
        var _atk = variable_instance_exists(id, "ataque_enemigo_activo") && ataque_enemigo_activo;
        if (_atk && !ea_ataque_prev && _tipo != 3) ea_ataque_t = _set.ataque_frames;
        ea_ataque_prev = _atk;

        // Disparo: disparo_timer vuelve a subir justo cuando dispara
        if (variable_instance_exists(id, "disparo_timer"))
        {
            if (disparo_timer > ea_disparo_prev) ea_disparo_t = 16;
            ea_disparo_prev = disparo_timer;
        }

        var _suelo = place_meeting(x, y + 1, obj_solid);
        var _aturdido = aturdido_timer > 0
            || (variable_instance_exists(id, "tiempo_desestabilizado") && tiempo_desestabilizado > 0);
        var _spr = _set.idle;
        var _img = 0;

        if (_tipo == 3)
        {
            // Centinela: mira hacia el jugador (su código la deja siempre mirando a la izquierda)
            if (_jug != noone && instance_exists(_jug)) mirando = (_jug.x >= x) ? 1 : -1;

            if (_aturdido && _set.aturdida != -1) _spr = _set.aturdida;
            else if (ea_disparo_t > 0 && _set.disparo != -1) { _spr = _set.disparo; _img = (ea_disparo_t > 10) ? 1 : 2; }
            else if (disparo_timer <= 15 && _set.disparo != -1) { _spr = _set.disparo; _img = 0; }   // cargando
            else _img = (_t div 20) mod max(1, sprite_get_number(_spr));
        }
        else
        {
            if (estado == EnemyState.KNOCKED_DOWN && _set.derribado != -1) _spr = _set.derribado;
            else if ((!_suelo || estado == EnemyState.AIRBORNE) && _set.aire != -1) _spr = _set.aire;
            else if (_aturdido && _set.aturdido != -1) _spr = _set.aturdido;
            else if (ea_ataque_t > 0 && _set.ataque != -1)
            {
                _spr = _set.ataque;
                var _n = sprite_get_number(_spr);
                _img = min(_n - 1, floor((_set.ataque_frames - ea_ataque_t) / _set.ataque_frames * _n));
            }
            else if (ea_disparo_t > 0 && _set.disparo != -1) { _spr = _set.disparo; _img = (ea_disparo_t > 8) ? 1 : 0; }
            else if (variable_instance_exists(id, "bloqueando") && bloqueando && _set.guardia != -1) _spr = _set.guardia;
            else if (_mov && _set.correr != -1) { _spr = _set.correr; _img = (_t div ((_tipo == 2) ? 9 : 6)) mod max(1, sprite_get_number(_set.correr)); }
            else _img = (_t div 20) mod max(1, sprite_get_number(_spr));
        }

        if (sprite_index != _spr) sprite_index = _spr;
        image_index = _img;
    }

    // Balas: esfera roja girada hacia donde viaja (cian si el jugador la devolvió con el parry)
    if (_C.bala != -1)
    {
        with (obj_proyectil)
        {
            if (!variable_instance_exists(id, "ea_mascara")) ea_mascara = sprite_index;
            mask_index = ea_mascara;
            sprite_index = _C.bala;
            image_speed = 0;
            if (vx != 0 || vy != 0) image_angle = point_direction(0, 0, vx, vy);
            image_blend = (equipo == "jugador") ? make_color_rgb(120, 230, 255) : c_white;
        }
    }
}
