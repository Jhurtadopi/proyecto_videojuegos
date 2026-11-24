event_inherited();

// Aviso del golpe: "!" que se pone rojo justo antes de golpear
if (atq_prep > 0)
{
    var _top = y - sprite_height - 26;
    draw_set_halign(fa_center);
    draw_set_color(atq_prep < 10 ? c_red : make_color_rgb(255, 170, 0));
    draw_text(x, _top, "!");
    draw_set_halign(fa_left);
}

// Tajo del golpe
if (atq_golpe_t > 0)
{
    draw_set_color(c_red);
    draw_set_alpha(atq_golpe_t / 8);
    var _cx = x + mirando * 20;
    draw_line_width(_cx, y - 44, _cx + mirando * 22, y - 10, 3);
    draw_set_alpha(1);
}
draw_set_color(c_white);
