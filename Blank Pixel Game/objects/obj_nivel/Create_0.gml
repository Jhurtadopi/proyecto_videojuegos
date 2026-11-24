// Controlador del nivel (uno por room de nivel). Lo pone generar_niveles.py.
// Código de creación: nombre, subtitulo, cielo_arriba / cielo_abajo (colores).
nombre = "Nivel";
subtitulo = "";
// Profundidad entre la capa de fondo de la room (100) y las instancias (0): el fondo y el terreno se
// dibujan en Draw (no en Draw Begin, que queda tapado por el color de la capa de fondo)
depth = 50;
cielo_arriba = make_color_rgb(10, 10, 26);
cielo_abajo = make_color_rgb(46, 16, 58);
neon_a = make_color_rgb(0, 230, 255);
neon_b = make_color_rgb(230, 40, 160);

inicio_x = 0;
inicio_y = 0;
colocado = false;

// Rooms de jefe sin portal propio: al no quedar instancias de "meta_al_vencer" aparece el portal a "siguiente"
meta_al_vencer = noone;
siguiente = -1;
meta_hecha = false;
t_inicio = current_time;
t_final = -1;
banner = 240;

global.nivel_canales = [];
// Al reaparecer en un checkpoint se recuperan los canales (compuertas, botones) que ya estaban abiertos
if (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room == room
    && variable_struct_exists(global.nivel_cp, "canales"))
{
    var _cc = global.nivel_cp.canales;
    array_copy(global.nivel_canales, 0, _cc, 0, array_length(_cc));
}
global.nivel_invulnerable = 0;
global.nivel_llaves = 0;
if (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room == room
    && variable_struct_exists(global.nivel_cp, "llaves")) global.nivel_llaves = global.nivel_cp.llaves;
global.nivel_flash = 0;
if (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room != room) global.nivel_cp = undefined;

// Fondo: dos capas de edificios con parallax (siempre iguales para la misma room)
random_set_seed(room_width * 7 + room_height);
fondo_lejos = [];
fondo_cerca = [];
var _x = -200;
while (_x < room_width * 0.3 + 1600)
{
    var _w = irandom_range(70, 150);
    array_push(fondo_lejos, { x: _x, w: _w, h: irandom_range(220, 460), s: irandom(99) });
    _x += _w + irandom_range(6, 26);
}
_x = -200;
while (_x < room_width * 0.55 + 1600)
{
    var _w2 = irandom_range(50, 120);
    array_push(fondo_cerca, { x: _x, w: _w2, h: irandom_range(120, 320), s: irandom(99) });
    _x += _w2 + irandom_range(20, 70);
}
randomize();
