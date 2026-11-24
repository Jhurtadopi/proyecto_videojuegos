t++;
if (recogido > 0) { recogido--; y -= 1; if (recogido <= 0) instance_destroy(); exit; }
vida_t--;
if (vida_t <= 0) { instance_destroy(); exit; }

var _j = nivel_jugador();
if (_j != noone && point_distance(x, y, _j.x, _j.y - 30) < 70)
{
    // Imán hacia el jugador
    x = lerp(x, _j.x, 0.18);
    y = lerp(y, _j.y - 30, 0.18);
    vsp = 0;
    if (point_distance(x, y, _j.x, _j.y - 30) < 18)
    {
        _j.vida = min(_j.vida_maxima, _j.vida + cura);
        recogido = 40;
    }
    exit;
}
vsp = min(vsp + 0.3, 8);
if (place_meeting(x, y + vsp, obj_solid))
{
    while (!place_meeting(x, y + sign(vsp), obj_solid)) y += sign(vsp);
    vsp = 0;
    hsp = 0;
}
y += vsp;
if (!place_meeting(x + hsp, y, obj_solid)) x += hsp; else hsp = 0;
