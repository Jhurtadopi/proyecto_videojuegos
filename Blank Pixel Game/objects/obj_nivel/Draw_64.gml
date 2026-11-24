var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

// Destello al reaparecer
if (global.nivel_flash > 0)
{
    draw_set_color(c_white);
    draw_set_alpha(global.nivel_flash / 14 * 0.5);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);
}

// Cronómetro
var _ms = (t_final >= 0) ? t_final : (current_time - t_inicio);
var _s = _ms div 1000;
var _txt = string(_s div 60) + ":" + string_replace_all(string_format(_s mod 60, 2, 0), " ", "0");
draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text(_gw / 2, 16, nombre + "   " + _txt);

// Cartel de inicio
if (banner > 0)
{
    var _a = min(1, banner / 40) * min(1, (240 - banner) / 20);
    draw_set_alpha(_a * 0.6);
    draw_set_color(c_black);
    draw_rectangle(0, _gh * 0.32, _gw, _gh * 0.32 + 84, false);
    draw_set_alpha(_a);
    draw_set_color(neon_a);
    draw_text_transformed(_gw / 2, _gh * 0.32 + 12, string_upper(nombre), 2.5, 2.5, 0);
    draw_set_color(c_ltgray);
    draw_text(_gw / 2, _gh * 0.32 + 58, subtitulo);
    draw_set_alpha(1);
}

// Fin del nivel
if (t_final >= 0)
{
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(0, _gh * 0.4, _gw, _gh * 0.4 + 70, false);
    draw_set_alpha(1);
    draw_set_color(neon_a);
    draw_text_transformed(_gw / 2, _gh * 0.4 + 10, "NIVEL COMPLETADO", 2.5, 2.5, 0);
    draw_set_color(c_white);
    draw_text(_gw / 2, _gh * 0.4 + 48, "Tiempo: " + _txt);
}
draw_set_halign(fa_left);
draw_set_color(c_white);
