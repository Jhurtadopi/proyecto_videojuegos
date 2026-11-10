// Estilo actual y último golpe, arriba a la derecha
var _x = display_get_gui_width() - 16;
var _swordmaster = (global.estilo == Estilo.SWORDMASTER);

draw_set_halign(fa_right);
draw_set_color(c_white);
draw_text(_x, 16, "Estilo: " + (_swordmaster ? "Swordmaster" : "Base") + " (Q cambia)");

if (_swordmaster)
{
    draw_text(_x, 36, "W + click en suelo: lanzar | Click en aire: corte | S + click en aire: estampar");
}

if (golpe_nombre_timer > 0)
{
    draw_set_color(c_yellow);
    draw_text(_x, 56, golpe_nombre);
}

draw_set_halign(fa_left);
draw_set_color(c_white);
