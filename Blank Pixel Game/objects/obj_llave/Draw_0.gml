if (recogida > 0) { nivel_texto(x, y - 14, "LLAVE OBTENIDA", make_color_rgb(255, 220, 90), recogida / 60); exit; }
var _b = (vsp == 0) ? sin(t * 0.1) * 3 - 6 : 0;
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(255, 200, 60));
draw_set_alpha(0.25 + 0.12 * sin(t * 0.15));
draw_circle(x, y - 8 + _b, 16, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_sprite(sprite_index, (t div 15) mod 2, x, y + _b);
var _j = nivel_jugador();
if (_j != noone && point_distance(x, y, _j.x, _j.y) < 260) nivel_texto(x, y - 24 + _b, "LLAVE", make_color_rgb(255, 220, 90), 0.9);
draw_set_color(c_white);
