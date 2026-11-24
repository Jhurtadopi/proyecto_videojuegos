t++;
if (recogida > 0) { recogida--; y -= 1; if (recogida <= 0) instance_destroy(); exit; }
var _j = nivel_jugador();
// Cerca, o tras 1,5 s en el suelo, vuela hacia el jugador (para que no se pueda dejar olvidada)
if (_j != noone && (point_distance(x, y, _j.x, _j.y - 30) < 80 || t > 90))
{
    x = lerp(x, _j.x, 0.2);
    y = lerp(y, _j.y - 30, 0.2);
    vsp = 0;
    if (point_distance(x, y, _j.x, _j.y - 30) < 18)
    {
        global.nivel_llaves = (variable_global_exists("nivel_llaves") ? global.nivel_llaves : 0) + 1;
        recogida = 60;
        with (obj_camara) aplicar_temblor(3, 10);
    }
    exit;
}
vsp = min(vsp + 0.3, 8);
if (place_meeting(x, y + vsp, obj_solid))
{
    while (!place_meeting(x, y + sign(vsp), obj_solid)) y += sign(vsp);
    vsp = 0;
}
y += vsp;
