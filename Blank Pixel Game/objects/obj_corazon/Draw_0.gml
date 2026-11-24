if (recogido > 0) { nivel_texto(x, y - 10, "+" + string(cura) + " VIDA", make_color_rgb(255, 90, 140), recogido / 40); exit; }
if (vida_t < 150 && (t div 4) mod 2 == 0) exit;
var _b = sin(t * 0.12) * 2;
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(255, 60, 120));
draw_set_alpha(0.25 + 0.1 * sin(t * 0.2));
draw_circle(x, y - 7 + _b, 11, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_sprite(sprite_index, (t div 20) mod 2, x, y + _b);
draw_set_color(c_white);
