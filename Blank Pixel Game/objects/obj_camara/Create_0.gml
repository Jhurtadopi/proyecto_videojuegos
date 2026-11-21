// Cámara con temblor (propio). Lo crea obj_mecanicas_jugador si no hay uno en la room.
// La room no usa views: se activa la view 0 del tamaño de la room para poder sacudirla.
if (view_camera[0] == -1) view_camera[0] = camera_create_view(0, 0, room_width, room_height);
view_enabled = true;
view_visible[0] = true;
camera_set_view_size(view_camera[0], room_width, room_height);
camera_set_view_pos(view_camera[0], 0, 0);
view_wport[0] = room_width;
view_hport[0] = room_height;

temblor_fuerza = 0;     // px máximos de desplazamiento
temblor_timer = 0;
temblor_total = 1;

// Uso: with (obj_camara) aplicar_temblor(fuerza_px, frames);
aplicar_temblor = function(_fuerza, _frames)
{
    // Solo reemplaza al temblor actual si el nuevo es más fuerte
    var _actual = temblor_fuerza * (temblor_timer / temblor_total);
    if (_fuerza >= _actual)
    {
        temblor_fuerza = _fuerza;
        temblor_timer = _frames;
        temblor_total = _frames;
    }
};
