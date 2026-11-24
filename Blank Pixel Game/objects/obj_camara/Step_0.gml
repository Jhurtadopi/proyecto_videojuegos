// Seguimiento (solo en rooms más grandes que la pantalla)
if (sigue)
{
    var _j = instance_exists(obj_jugador) ? instance_find(obj_jugador, 0) : noone;
    if (_j != noone)
    {
        var _mira = 1;
        with (obj_mecanicas_jugador) _mira = mirando;
        adelanto_actual = lerp(adelanto_actual, _mira * adelanto, 0.04);
        var _ox = clamp(_j.x + adelanto_actual - vista_w / 2, 0, room_width - vista_w);
        var _oy = clamp(_j.y - vista_h * altura_jugador, 0, room_height - vista_h);
        cam_x = lerp(cam_x, _ox, suavizado_x);
        cam_y = lerp(cam_y, _oy, suavizado_y);
    }
}

// El temblor sigue durante el hitstop (a propósito: el golpe se siente más)
var _dx = 0, _dy = 0;
if (temblor_timer > 0)
{
    temblor_timer--;
    var _k = temblor_fuerza * (temblor_timer / temblor_total);
    _dx = random_range(-_k, _k);
    _dy = random_range(-_k, _k);
}
camera_set_view_pos(view_camera[0], round(cam_x + _dx), round(cam_y + _dy));
