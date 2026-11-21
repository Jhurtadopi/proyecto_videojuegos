// ==============================
// DESLIZAMIENTO EN PARED (propio; no modifica scr_mec_doble_salto)
// Cayendo pegado a una pared y manteniendo la dirección hacia ella, se baja despacio.
// El salto en pared sigue siendo de scr_mec_doble_salto. Contexto: obj_mecanicas_jugador.
// Pendiente: desactivarlo en el estilo Underdog (cuando exista).
// ==============================

function mec_pared_crear()
{
    pared_vel_max = 2.5;        // px/frame máximos de caída mientras se desliza
    pared_dir = 0;              // 1 pared a la derecha, -1 a la izquierda, 0 sin deslizar
    pared_t = 0;                // para las chispas
}

function mec_pared_deslizando()
{
    return pared_dir != 0;
}

// End Step: después del movimiento de obj_jugador y de las demás mecánicas
function mec_pared_fin()
{
    var _j = jugador;
    pared_dir = 0;

    if (mec_en_suelo(_j) || _j.vsp <= 0) return;
    if (mec_gancho_activo() || mec_gancho_enemigo_activo() || mec_dash_activo() || walljump_bloqueo > 0) return;

    var _picado = false;
    with (obj_mec_golpe) _picado = sm_picado;
    if (_picado) return;

    var _pared = mec_pared(_j);
    var _input = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    if (_pared == 0 || _input != _pared) return;

    pared_dir = _pared;
    pared_t++;

    // obj_jugador ya cayó este frame (hasta 12 px): se limita a pared_vel_max
    var _limite = y_inicio + pared_vel_max;
    if (_j.y > _limite) mec_mover_con_choque(_j, 0, _limite - _j.y);
    _j.vsp = pared_vel_max;
}

// Draw: chispas cian donde la mano roza la pared
function mec_pared_dibujar()
{
    if (pared_dir == 0) return;
    var _j = jugador;
    var _x = (pared_dir == 1) ? _j.bbox_right + 1 : _j.bbox_left - 1;
    var _y = _j.y - 40;

    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(0, 230, 255));
    repeat (3)
    {
        draw_set_alpha(random_range(0.4, 0.9));
        var _dy = irandom_range(-6, 10);
        draw_rectangle(_x - pared_dir * irandom(4), _y + _dy, _x - pared_dir * irandom(4) + 1, _y + _dy + 1, false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
