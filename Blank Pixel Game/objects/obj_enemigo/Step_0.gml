if (global.hitstop_timer > 0) exit;

flash_timer = max(0, flash_timer - 1);
aturdido_timer = max(0, aturdido_timer - 1);
conexion_underdog_timer = max(0, conexion_underdog_timer - 1);

// Mirar hacia el jugador
if (instance_exists(obj_jugador) && obj_jugador.x != x)
{
    mirando = sign(obj_jugador.x - x);
}

if (lanzable)
{
    if (estado == EnemyState.KNOCKED_DOWN)
    {
        derribado_timer--;
        if (derribado_timer <= 0) estado = EnemyState.NORMAL;
    }

    vsp = min(vsp + gravedad_enemigo, vsp_max);

    if (place_meeting(x + hsp, y, obj_solid))
    {
        while (!place_meeting(x + sign(hsp), y, obj_solid)) x += sign(hsp);
        hsp = 0;
    }

    x += hsp;

    if (place_meeting(x, y + vsp, obj_solid))
    {
        while (!place_meeting(x, y + sign(vsp), obj_solid)) y += sign(vsp);

        if (vsp > 0)
        {
            juggle_cuenta = 0;      // tocó el suelo: el juggle vuelve a empezar

            if (estampado)
            {
                estampado = false;
                aplicar_danio(danio_estampado);
                if (vida <= 0) exit;

                estado = EnemyState.KNOCKED_DOWN;
                derribado_timer = derribado_frames;
                conexion_underdog_timer = conexion_underdog_frames;   // ventana para el Underdog
            }
            else if (estado == EnemyState.AIRBORNE)
            {
                estado = EnemyState.NORMAL;
            }
        }

        vsp = 0;
    }

    y += vsp;

    if (place_meeting(x, y + 1, obj_solid))
    {
        hsp *= friccion_suelo;
        if (abs(hsp) < 0.1) hsp = 0;
    }
}

if (instance_exists(hurtbox))
{
    hurtbox.x = x;
    hurtbox.y = y;
}
