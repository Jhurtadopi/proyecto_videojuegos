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
        + "\nGolpe: " + (mec_parry_en_ventana() ? "VENTANA PARRY" : (mec_parry_golpeando() ? "recuperacion" : "-")));
}
else
{
    draw_text(16, 16, "Jugador derrotado. Pulsa R para reiniciar.");
}

draw_text(16, display_get_gui_height() - 32,
    "A/D mover | Shift correr | Espacio saltar (x2, en pared) | K dash | J golpe/parry | Abajo agacharse | R reiniciar");
