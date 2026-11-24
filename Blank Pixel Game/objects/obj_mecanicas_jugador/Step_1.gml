// Reiniciar la room (pruebas). R queda libre para recargar el arma del Gunner.
if (keyboard_check_pressed(vk_backspace))
{
    room_restart();
    exit;
}

// Cambiar de room (pruebas): F1 Room1, F2 Room2, F3 Room_Underdog
if (keyboard_check_pressed(vk_f1)) { room_goto(Room1); exit; }
if (keyboard_check_pressed(vk_f2)) { room_goto(Room2); exit; }
if (keyboard_check_pressed(vk_f3)) { room_goto(Room_Underdog); exit; }

jugador = instance_exists(obj_jugador) ? instance_find(obj_jugador, 0) : noone;

// Colisión fija de 32x64 aunque los sprites del jugador sean más grandes (sin editar obj_jugador)
if (jugador != noone) jugador.mask_index = spr_hurtbox;

// obj_jugador no se mueve durante el hitstop; las mecánicas tampoco
en_hitstop = variable_global_exists("hitstop_timer") && global.hitstop_timer > 0;

if (jugador == noone || en_hitstop) exit;

var _dir = keyboard_check(ord("D")) - keyboard_check(ord("A"));
if (_dir != 0) mirando = _dir;

x_inicio = jugador.x;
y_inicio = jugador.y;

mec_underdog_inicio();       // primero: bajo tierra bloquea el dash y el gancho normales
mec_gunner_inicio();         // dispara al cursor y cambia de arma (en estilo Gunner)
mec_doble_salto_inicio();
mec_dash_inicio();
mec_buffer_inicio();
mec_parry_inicio();
mec_gancho_enemigo_inicio();   // antes del gancho normal: si apunta a un enemigo, lo bloquea
mec_gancho_inicio();
