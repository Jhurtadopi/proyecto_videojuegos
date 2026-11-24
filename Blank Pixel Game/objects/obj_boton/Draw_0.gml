draw_self();
var _col = pulsado ? make_color_rgb(60, 230, 120) : make_color_rgb(230, 40, 50);
gpu_set_blendmode(bm_add);
draw_set_color(_col);
draw_set_alpha(pulsado ? 0.15 + brillo / 60 : 0.15 + 0.15 * abs(sin(t * 0.08)));
draw_circle(x, y - 6, 14 + brillo * 0.8, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

var _j = nivel_jugador();
if (!pulsado && _j != noone && point_distance(x, y, _j.x, _j.y) < 160)
    nivel_texto(x, y - 18, "Pisa o golpea el boton", c_yellow, 0.6 + 0.4 * abs(sin(t * 0.1)));
draw_set_color(c_white);
