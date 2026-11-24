t++;
anim = max(0, anim - 1);
var _cp = (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room == room) ? global.nivel_cp : undefined;
if (!revisado)
{
    revisado = true;
    if (!is_undefined(_cp) && _cp.x == x && _cp.y == y) activo = true;
}
var _j = nivel_jugador();
if (!activo && _j != noone && place_meeting(x, y, _j) && (is_undefined(_cp) || x > _cp.x))
{
    global.nivel_cp = { room: room, x: x, y: y };
    activo = true;
    anim = 70;
    _j.vida = min(_j.vida_maxima, _j.vida + 30);
    with (obj_checkpoint) if (id != other.id && x < other.x) activo = true;   // los anteriores quedan encendidos
}
image_index = activo ? 1 : 0;
