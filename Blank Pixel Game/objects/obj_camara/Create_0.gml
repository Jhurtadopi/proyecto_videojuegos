// Cámara (propia). Lo crea obj_mecanicas_jugador si no hay uno en la room.
// Rooms del tamaño de la pantalla: cámara fija. Rooms más grandes (niveles): sigue al jugador
// con desplazamiento lateral suave, mira un poco hacia donde corre y no se sale de la room.
// El temblor se suma encima en ambos casos.
// Resolución fija del juego: 1366x768. Los niveles son más grandes que la pantalla; sin esto GameMaker
// toma el tamaño de la room para la imagen del juego y la ventana, y todo se ve estirado.
var _rw = 1366, _rh = 768;
if (surface_get_width(application_surface) != _rw || surface_get_height(application_surface) != _rh)
    surface_resize(application_surface, _rw, _rh);
if (!window_get_fullscreen() && (window_get_width() != _rw || window_get_height() != _rh))
{
    window_set_size(_rw, _rh);
    call_later(1, time_source_units_frames, function() { window_center(); });
}
display_set_gui_size(_rw, _rh);

vista_w = min(1366, room_width);
vista_h = min(768, room_height);

if (view_camera[0] == -1) view_camera[0] = camera_create_view(0, 0, vista_w, vista_h);
view_enabled = true;
view_visible[0] = true;
camera_set_view_size(view_camera[0], vista_w, vista_h);
view_wport[0] = 1366;
view_hport[0] = 768;

sigue = (room_width > vista_w || room_height > vista_h);
suavizado_x = 0.12;
suavizado_y = 0.10;
adelanto = 140;             // px que mira hacia delante en la dirección en que mira el jugador
adelanto_actual = 0;
altura_jugador = 0.62;      // el jugador queda a esta fracción de la altura de la vista

cam_x = 0;
cam_y = 0;
var _j = instance_exists(obj_jugador) ? instance_find(obj_jugador, 0) : noone;
if (sigue && _j != noone)
{
    cam_x = clamp(_j.x - vista_w / 2, 0, room_width - vista_w);
    cam_y = clamp(_j.y - vista_h * altura_jugador, 0, room_height - vista_h);
}
camera_set_view_pos(view_camera[0], cam_x, cam_y);

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

// Salta la cámara a una posición sin suavizado (respawn en un checkpoint)
saltar_a = function(_x, _y)
{
    cam_x = clamp(_x - vista_w / 2, 0, room_width - vista_w);
    cam_y = clamp(_y - vista_h * altura_jugador, 0, room_height - vista_h);
};
