// Ultimate del Swordmaster: oscurecer, cortes, destello y barra de carga
mec_swordmaster_ultimate_dibujar();

// Estilo actual y último golpe, arriba a la derecha
var _x = display_get_gui_width() - 16;
var _swordmaster = (global.estilo == Estilo.SWORDMASTER);

draw_set_halign(fa_right);
draw_set_color(c_white);
draw_text(_x, 16, "Estilo: " + mec_estilo_nombre(global.estilo) + " (Q cambia)");

if (_swordmaster)
{
    draw_text(_x, 36, "W + click en suelo: lanzar | Click en aire: corte | S + click en aire: estampar");
}
else if (global.estilo == Estilo.UNDERDOG)
{
    draw_text(_x, 36, "S: excavar | W + click: taladro arriba | Bajo tierra: Espacio emerger, Shift dash, click pinchazo/arrastre, W + click perforar");
}

if (golpe_nombre_timer > 0)
{
    draw_set_color(c_yellow);
    draw_text(_x, 56, golpe_nombre);
}

draw_set_halign(fa_left);
draw_set_color(c_white);
