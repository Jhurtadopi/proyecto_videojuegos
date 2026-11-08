// Indicadores visuales encima del jugador (no cambia cómo se dibuja obj_jugador)
if (jugador == noone || !instance_exists(jugador)) exit;

var _j = jugador;

// Flecha: hacia dónde mira
var _cy = _j.y - _j.sprite_height - 10;
draw_set_color(c_white);
draw_triangle(_j.x + mirando * 8, _cy, _j.x - mirando * 4, _cy - 5, _j.x - mirando * 4, _cy + 5, false);

// Dash: tinte celeste
if (mec_dash_activo())
{
    draw_set_alpha(0.5);
    draw_set_color(c_aqua);
    draw_rectangle(_j.bbox_left, _j.bbox_top, _j.bbox_right, _j.bbox_bottom, false);
    draw_set_alpha(1);
}

// Golpe: zona amarilla en la ventana de parry, gris en la recuperación
if (mec_parry_golpeando())
{
    var _z = mec_parry_zona();
    draw_set_color(mec_parry_en_ventana() ? c_yellow : c_gray);
    draw_rectangle(_z[0], _z[1], _z[2], _z[3], true);
}

if (parry_exito_timer > 0)
{
    draw_set_halign(fa_center);
    draw_set_color(c_yellow);
    draw_text(_j.x, _cy - 28, "PARRY!");
    draw_set_halign(fa_left);
}

draw_set_color(c_white);
