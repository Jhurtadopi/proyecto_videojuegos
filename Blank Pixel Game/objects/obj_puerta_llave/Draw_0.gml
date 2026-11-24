draw_sprite_ext(sprite_index, 0, x, y, 1, 1, 0, c_white, 1 - abriendo);
if (abriendo > 0)
{
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(255, 210, 80));
    draw_set_alpha(0.4 * (1 - abriendo));
    draw_rectangle(bbox_left - 4, bbox_top, bbox_right + 4, bbox_bottom, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
var _j = nivel_jugador();
if (abriendo == 0 && _j != noone && point_distance(x, y, _j.x, _j.y) < 220)
{
    var _tiene = variable_global_exists("nivel_llaves") && global.nivel_llaves > 0;
    var _txt = _tiene ? "Acercate para abrir" : "Cerrada: necesitas la llave del guardian";
    if (_tiene && requiere >= 0 && !nivel_canal_activo(requiere)) _txt = "Acaba con todos para usar la llave";
    nivel_texto(x, bbox_top - 8, _txt, make_color_rgb(255, 210, 90), 0.9);
}
draw_set_color(c_white);
