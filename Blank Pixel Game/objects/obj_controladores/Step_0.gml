if (global.hitstop_timer > 0)
{
    global.hitstop_timer--;
}

if (cambiando_room) exit;
if (global.hitstop_timer > 0) exit; // Respeta el hitstop de tu sistema

// Comprueba si quedan enemigos (obj_enemigo y todos sus hijos)
if (instance_number(obj_enemigo) <= 0)
{
    timer_cambio--;

    if (timer_cambio <= 0)
    {
        cambiando_room = true;

        if (room_destino != noone && room_exists(room_destino))
        {
            room_goto(room_destino);
        }
        else if (room_exists(room_next(room)))
        {
            room_goto_next();
        }
    }
}
else
{
    // Si aparece algún enemigo nuevo antes de cambiar, reinicia el delay
    timer_cambio = delay_cambio;
}