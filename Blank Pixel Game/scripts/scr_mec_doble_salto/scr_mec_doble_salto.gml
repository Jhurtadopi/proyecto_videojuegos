// ==============================
// DOBLE SALTO Y SALTO EN PARED
// El salto desde el suelo (coyote, buffer, salto variable) lo hace obj_jugador.
// Aquí solo se agregan los saltos en el aire y en la pared.
// ==============================

function mec_doble_salto_crear()
{
    saltos_aire_max = 1;            // saltos extra en el aire (1 = doble salto)
    saltos_aire = saltos_aire_max;
    fuerza_salto_aire = -10;        // un poco menor que el salto desde el suelo

    walljump_fuerza_x = 6;          // empuje horizontal inicial al saltar desde la pared
    walljump_bloqueo_max = 10;      // frames en los que ese empuje manda sobre el input
    walljump_bloqueo = 0;
    walljump_dir = 0;

    salto_extra_este_frame = false;
}

// Begin Step: antes del Step de obj_jugador
function mec_doble_salto_inicio()
{
    var _j = jugador;
    var _suelo = mec_en_suelo(_j);

    if (_suelo) saltos_aire = saltos_aire_max;
    walljump_bloqueo = max(0, walljump_bloqueo - 1);
    salto_extra_este_frame = false;

    if (!keyboard_check_pressed(vk_space)) return;

    // Si obj_jugador va a hacer su salto normal este frame (suelo o coyote), no hacer nada
    if (_suelo || _j.coyote_timer > 1) return;

    var _pared = mec_pared(_j);

    if (_pared != 0)
    {
        // Salto en pared: no gasta el salto aéreo
        _j.vsp = _j.fuerza_salto;
        walljump_dir = -_pared;
        walljump_bloqueo = walljump_bloqueo_max;
        mirando = walljump_dir;
        salto_extra_este_frame = true;
    }
    else if (saltos_aire > 0)
    {
        _j.vsp = fuerza_salto_aire;
        saltos_aire--;
        salto_extra_este_frame = true;
    }
    // obj_jugador suma la gravedad y aplica el salto variable al soltar espacio
}

// End Step: después del Step de obj_jugador
function mec_doble_salto_fin()
{
    // Evita que el jump buffer de obj_jugador repita el salto al aterrizar
    if (salto_extra_este_frame) jugador.buffer_timer = 0;

    // Empuje del salto en pared: reemplaza el movimiento horizontal del input (se va reduciendo)
    if (walljump_bloqueo > 0)
    {
        var _avance = walljump_fuerza_x * (walljump_bloqueo / walljump_bloqueo_max);
        mec_mover_hasta_x(jugador, x_inicio + walljump_dir * _avance);
    }
}
