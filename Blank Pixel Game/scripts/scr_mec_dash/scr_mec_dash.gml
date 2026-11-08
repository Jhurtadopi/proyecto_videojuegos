// ==============================
// DASH (versión base = swordmaster: lateral, rápido, sin altura)
// Los estilos podrán cambiar estos parámetros.
// ==============================

function mec_dash_crear()
{
    dash_velocidad = 9;
    dash_duracion = 10;             // frames
    dash_cooldown_max = 30;
    dash_impulso_y = 0;             // < 0 para ganar altura (estilos futuros, ej. boxer)

    dash_timer = 0;
    dash_cooldown = 0;
    dash_dir = 1;
    dash_aire_disponible = true;    // un dash por cada estancia en el aire
}

function mec_dash_activo()
{
    return dash_timer > 0;
}

// Begin Step
function mec_dash_inicio()
{
    var _j = jugador;
    var _suelo = mec_en_suelo(_j);

    dash_cooldown = max(0, dash_cooldown - 1);
    if (_suelo) dash_aire_disponible = true;

    if (dash_timer == 0 && !mec_parry_golpeando() && !mec_gancho_activo()
        && keyboard_check_pressed(vk_shift) && dash_cooldown == 0
        && (_suelo || dash_aire_disponible))
    {
        var _dir = keyboard_check(ord("D")) - keyboard_check(ord("A"));
        dash_dir = (_dir != 0) ? _dir : mirando;
        mirando = dash_dir;

        dash_timer = dash_duracion;
        dash_cooldown = dash_cooldown_max;
        if (!_suelo) dash_aire_disponible = false;

        walljump_bloqueo = 0;       // el dash cancela el empuje del salto en pared
        if (dash_impulso_y != 0) _j.vsp = dash_impulso_y;
    }

    // Sin impulso vertical: obj_jugador suma gravedad, así que se compensa para quedar en 0
    if (dash_timer > 0 && dash_impulso_y == 0) _j.vsp = -_j.gravedad;
}

// End Step
function mec_dash_fin()
{
    if (dash_timer <= 0) return;

    // Si obj_jugador saltó durante el dash (coyote/buffer), el salto cancela el dash
    if (jugador.vsp < -1)
    {
        dash_timer = 0;
        return;
    }

    // Reemplaza el movimiento horizontal del input por el del dash
    mec_mover_hasta_x(jugador, x_inicio + dash_dir * dash_velocidad);
    if (dash_impulso_y == 0) jugador.vsp = 0;

    dash_timer--;
}
