var _gw = display_get_gui_width();
draw_set_halign(fa_center);
if (activa && !abierta)
{
    draw_set_color(c_black);
    draw_text(_gw / 2 + 1, 41, mensaje + ": " + string(restantes));
    draw_set_color(make_color_rgb(255, 90, 90));
    draw_text(_gw / 2, 40, mensaje + ": " + string(restantes));
    if (jefe_nombre != "" && instance_exists(jefe))
    {
        var _gh = display_get_gui_height();
        var _bw = 520, _bx = _gw / 2 - _bw / 2, _by = _gh - 64;
        var _f = clamp(jefe.vida / max(1, jefe.vida_maxima), 0, 1);
        draw_set_color(c_black);
        draw_rectangle(_bx - 3, _by - 3, _bx + _bw + 3, _by + 17, false);
        draw_set_color(make_color_rgb(60, 20, 24));
        draw_rectangle(_bx, _by, _bx + _bw, _by + 14, false);
        draw_set_color(make_color_rgb(230, 150, 40));
        draw_rectangle(_bx, _by, _bx + _bw * _f, _by + 14, false);
        draw_set_color(c_black);
        draw_text(_gw / 2 + 1, _by - 21, jefe_nombre);
        draw_set_color(make_color_rgb(255, 210, 120));
        draw_text(_gw / 2, _by - 22, jefe_nombre);
    }
}
else if (aviso > 0)
{
    draw_set_alpha(min(1, aviso / 30));
    draw_set_color(make_color_rgb(0, 230, 255));
    draw_text_transformed(_gw / 2, 40, (premio == obj_llave) ? "RECOGE LA LLAVE" : ((jefe_nombre != "") ? "CAMINO ABIERTO" : "ZONA DESPEJADA"), 1.6, 1.6, 0);
    draw_set_alpha(1);
}
draw_set_halign(fa_left);
draw_set_color(c_white);
