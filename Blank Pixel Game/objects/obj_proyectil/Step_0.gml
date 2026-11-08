if (global.hitstop_timer > 0) exit;

x += vx;
y += vy;

// Empuja en la dirección en la que viaja
knockback_x = sign(vx) * 4;

vida_frames--;

if (vida_frames <= 0 || place_meeting(x, y, obj_solid))
{
    instance_destroy();
}
