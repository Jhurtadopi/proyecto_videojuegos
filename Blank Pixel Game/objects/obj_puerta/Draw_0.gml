draw_sprite_ext(sprite_index, 0, x, y, 1, 1, 0, c_white, (1 - abriendo) * (0.85 + 0.15 * sin(t * 0.4)));
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(230, 40, 160));
draw_set_alpha(0.12 * (1 - abriendo));
draw_rectangle(bbox_left - 6, bbox_top, bbox_right + 6, bbox_bottom, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

var _j = nivel_jugador();
if (abriendo == 0 && _j != noone && point_distance(x, y, _j.x, _j.y) < 200)
    nivel_texto(x, bbox_top - 8, "Cerrada: busca el boton", make_color_rgb(255, 140, 220), 0.8);
draw_set_color(c_white);
