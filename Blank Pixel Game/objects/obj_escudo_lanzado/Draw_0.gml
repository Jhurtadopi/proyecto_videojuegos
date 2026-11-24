// Con el sprite del escudo (origen abajo-centro) se compensa para girar sobre su centro.
// Sin sprite, se dibuja una sierra por código.
if (escudo_spr != -1)
{
    var _h = sprite_get_height(escudo_spr) * escala;
    var _p = mec_animacion_pos_rotada(x, y + _h / 2, _h, ang);
    draw_sprite_ext(escudo_spr, 0, _p[0], _p[1], escala, escala, ang, c_white, 1);
}
else
{
    var _r = 16;
    draw_set_color(make_color_rgb(70, 74, 92));
    draw_circle(x, y, _r, false);
    // Dientes de sierra
    draw_set_color(make_color_rgb(190, 196, 210));
    for (var k = 0; k < 12; k++)
    {
        var _a = ang + k * 30;
        draw_triangle(x + lengthdir_x(_r - 2, _a - 8), y + lengthdir_y(_r - 2, _a - 8),
                      x + lengthdir_x(_r - 2, _a + 8), y + lengthdir_y(_r - 2, _a + 8),
                      x + lengthdir_x(_r + 6, _a + 10), y + lengthdir_y(_r + 6, _a + 10), false);
    }
    draw_set_color(make_color_rgb(30, 30, 40));
    draw_circle(x, y, _r, true);
    // Núcleo cian
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(0, 230, 255));
    draw_circle(x, y, 5, false);
    gpu_set_blendmode(bm_normal);
}

// Estela de giro mientras vuela
if (estado != 1)
{
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(0, 230, 255));
    draw_set_alpha(0.35);
    draw_circle(x, y, 20, true);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
draw_set_color(c_white);
