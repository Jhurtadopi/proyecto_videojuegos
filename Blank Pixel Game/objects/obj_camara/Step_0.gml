// El temblor sigue durante el hitstop (a propósito: el golpe se siente más)
if (temblor_timer > 0)
{
    temblor_timer--;
    var _k = temblor_fuerza * (temblor_timer / temblor_total);
    camera_set_view_pos(view_camera[0], round(random_range(-_k, _k)), round(random_range(-_k, _k)));
}
else
{
    camera_set_view_pos(view_camera[0], 0, 0);
}
