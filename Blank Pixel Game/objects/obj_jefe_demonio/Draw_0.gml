// Estela de las embestidas y del escape
var _col_estela = (fase == 2) ? make_color_rgb(255, 40, 40) : make_color_rgb(255, 120, 40);
gpu_set_blendmode(bm_add);
for (var i = 0; i < array_length(estela); i++)
{
    var _e = estela[i];
    draw_sprite_ext(_e.s, _e.i, _e.x, _e.y, _e.m, 1, 0, _col_estela, _e.a);
}
// Aura roja en la fase 2
if (aura > 0)
{
    draw_set_color(make_color_rgb(255, 30, 30));
    draw_set_alpha(aura * (0.18 + 0.08 * sin(t * 0.2)));
    draw_ellipse(x - 30, y - 70, x + 30, y + 4, false);
}
// Portales de invocación / teletransporte
for (var i = 0; i < array_length(portales); i++)
{
    var _p = portales[i];
    draw_set_color(make_color_rgb(200, 30, 60));
    draw_set_alpha(_p.t / 30);
    draw_ellipse(_p.x - 18, _p.y - 28 + _p.t * 0.3, _p.x + 18, _p.y + 28 - _p.t * 0.3, false);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);

var _a = alpha;
if (invulnerable > 0 && ia == "escape" && fase == 1) _a *= 0.6;
var _col = (aturdido_timer > 0) ? make_color_rgb(255, 225, 140) : c_white;
if (flash_timer > 0) gpu_set_fog(true, c_white, 0, 1);
draw_sprite_ext(sprite_index, image_index, x, y, mirando, 1, 0, _col, _a);
if (flash_timer > 0) gpu_set_fog(false, c_white, 0, 0);

// Aviso de la embestida: destello en los ojos
if (ia == "dash" && ia_t < round(14 / ((fase == 2) ? 1.4 : 1)))
{
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(255, 230, 60));
    draw_set_alpha(0.8);
    draw_circle(x + mirando * 6, y - sprite_get_height(sprite_index) + 12, 4 + (ia_t mod 4), false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
draw_set_color(c_white);
