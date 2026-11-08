if (global.hitstop_timer > 0) exit;

flash_timer = max(0, flash_timer - 1);

// Mirar hacia el jugador
if (instance_exists(obj_jugador) && obj_jugador.x != x)
{
    mirando = sign(obj_jugador.x - x);
}

if (instance_exists(hurtbox))
{
    hurtbox.x = x;
    hurtbox.y = y;
}
