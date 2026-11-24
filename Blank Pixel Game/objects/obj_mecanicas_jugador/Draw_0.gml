// Indicadores visuales encima del jugador (no cambia cómo se dibuja obj_jugador)
if (jugador == noone || !instance_exists(jugador)) exit;

// Estela del dash y jugador rotado durante las volteretas (en el resto de frames se dibuja solo)
mec_animacion_dibujar_estela();
mec_animacion_dibujar();
mec_underdog_dibujar();
<<<<<<< HEAD
mec_gunner_dibujar();
=======
mec_ud_robot_dibujar();
mec_shield_dibujar();
>>>>>>> bd2a099f0fe9a40fc91c0ab97a81a6e00d405b96

var _j = jugador;

// Flecha: hacia dónde mira
var _cy = _j.y - _j.sprite_height - 10;
draw_set_color(c_white);
draw_triangle(_j.x + mirando * 8, _cy, _j.x - mirando * 4, _cy - 5, _j.x - mirando * 4, _cy + 5, false);

// Golpe: zona amarilla en la ventana de parry, gris en la recuperación
if (mec_parry_golpeando())
{
    var _z = mec_parry_zona();
    if (instance_exists(obj_mec_golpe) && !is_undefined(obj_mec_golpe.golpe_zona)) _z = obj_mec_golpe.golpe_zona;
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

// Gancho: cable de energía desde la mano (alterna) hasta la punta o el ancla
mec_animacion_dibujar_gancho();
mec_gancho_enemigo_dibujar();
mec_pared_dibujar();

draw_set_color(c_white);
