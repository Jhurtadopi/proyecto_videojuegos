t++;
if (nivel_canal_activo(canal))
{
    if (abriendo == 0) with (obj_camara) aplicar_temblor(5, 24);
    abriendo = min(1, abriendo + 1 / 45);
    y -= 2;
    if (abriendo >= 1) instance_destroy();
    exit;
}
var _j = nivel_jugador();
if (_j != noone && abs(_j.x - x) < 56 && _j.y > bbox_top && _j.y - 64 < bbox_bottom
    && variable_global_exists("nivel_llaves") && global.nivel_llaves > 0
    && (requiere < 0 || nivel_canal_activo(requiere)))
{
    global.nivel_llaves--;
    nivel_activar_canal(canal);
}
