// HUD de depuración para probar mecánicas
draw_set_halign(fa_left);
draw_set_color(c_white);

if (jugador != noone && instance_exists(jugador))
{
    var _e = jugador.estado;
    var _nombre = (_e >= 0 && _e < array_length(nombres_estado)) ? nombres_estado[_e] : string(_e);

    draw_text(16, 16,
        "Estado (obj_jugador): " + _nombre
        + "\nVida: " + string(jugador.vida) + " / " + string(jugador.vida_maxima)
        + "\nSaltos en aire: " + string(saltos_aire) + " / " + string(saltos_aire_max)
        + "\nDash: " + (mec_dash_activo() ? "ACTIVO" : (dash_cooldown > 0 ? "cooldown " + string(dash_cooldown) : "listo"))
        + (dash_aire_disponible ? "" : " (dash aereo usado)")
        + "\nGolpe: " + (mec_parry_en_ventana() ? "VENTANA PARRY" : (mec_parry_golpeando() ? "recuperacion" : "-"))
        + "\nGancho: " + (gancho_estado == GanchoEstado.BALANCEANDO ? "BALANCEANDO" :
            (gancho_estado == GanchoEstado.LANZANDO ? "lanzando" :
            (gancho_cooldown > 0 ? "cooldown " + string(gancho_cooldown) : "listo"))));
}
else
{
    draw_text(16, 16, "Jugador derrotado. Pulsa R para reiniciar.");
}

draw_text(16, display_get_gui_height() - 32,
    "A/D mover | Espacio saltar (x2, en pared) | Shift dash (en pleno gancho acelera el balanceo) | Click izq. golpe/parry | Abajo agacharse\n"
    + "Mantener click der. para el gancho (A/D impulsan el balanceo, W retrae, S vuelve al punto si estas arriba) | R reiniciar");

// Mira del gancho: círculo que sigue al cursor (reemplaza al puntero del sistema)
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

var _color_mira = c_white;
if (gancho_estado != GanchoEstado.INACTIVO) _color_mira = c_yellow;
else if (gancho_cooldown > 0) _color_mira = c_gray;
else if (gancho_hay_objetivo) _color_mira = c_lime;

draw_set_color(_color_mira);
draw_circle(_mx, _my, 6, true);
draw_line(_mx - 10, _my, _mx - 4, _my);
draw_line(_mx + 4, _my, _mx + 10, _my);
draw_line(_mx, _my - 10, _mx, _my - 4);
draw_line(_mx, _my + 4, _mx, _my + 10);
draw_set_color(c_white);
