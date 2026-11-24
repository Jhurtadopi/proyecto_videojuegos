t++;
anim = max(0, anim - 1);
var _cp = (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room == room) ? global.nivel_cp : undefined;
var _cp_orden = (!is_undefined(_cp) && variable_struct_exists(_cp, "orden")) ? _cp.orden : -1;
if (!revisado)
{
    revisado = true;
    if (!is_undefined(_cp) && orden <= _cp_orden) activo = true;
}
var _j = nivel_jugador();
if (!activo && _j != noone && place_meeting(x, y, _j) && orden > _cp_orden)
{
    var _canales = [];
    if (variable_global_exists("nivel_canales")) array_copy(_canales, 0, global.nivel_canales, 0, array_length(global.nivel_canales));
    var _llaves = variable_global_exists("nivel_llaves") ? global.nivel_llaves : 0;
    global.nivel_cp = { room: room, x: x, y: y, orden: orden, canales: _canales, llaves: _llaves };
    activo = true;
    anim = 70;
    _j.vida = min(_j.vida_maxima, _j.vida + 30);
    with (obj_checkpoint) if (id != other.id && orden < other.orden) activo = true;   // los anteriores quedan encendidos
}
image_index = activo ? 1 : 0;
