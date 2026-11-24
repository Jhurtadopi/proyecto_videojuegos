global.nivel_invulnerable = max(0, global.nivel_invulnerable - 1);
global.nivel_flash = max(0, global.nivel_flash - 1);
banner = max(0, banner - 1);

var _j = nivel_jugador();
if (!colocado)
{
    // El terreno se dibuja con tiles propios: los obj_solid del nivel se ocultan
    with (obj_solid) if (object_index == obj_solid) visible = false;
    if (_j != noone)
    {
        inicio_x = _j.x;
        inicio_y = _j.y;
        var _p = nivel_punto_reaparicion();
        nivel_mover_jugador(_p[0], _p[1]);
        colocado = true;
    }
}

// Caída al vacío
if (_j != noone && _j.y > room_height + 96) nivel_reaparecer(15);

// Jefe vencido: portal de salida
if (meta_al_vencer != noone && colocado && !meta_hecha && instance_number(meta_al_vencer) == 0)
{
    meta_hecha = true;
    var _m = instance_create_layer(room_width / 2, inicio_y, "Instances", obj_meta);
    _m.siguiente = siguiente;
    with (obj_camara) aplicar_temblor(8, 30);
}
