<<<<<<< HEAD
// Reiniciar la room (pruebas). R queda libre para recargar el arma del Gunner.
if (keyboard_check_pressed(vk_backspace))
=======
// Golpes de enemigos cuyo dueño ya no existe (murió con el golpe activo): se desactivan.
// obj_hitbox (de otro colaborador) renueva su alarma mientras toca una hurtbox y, con el jugador en
// guardia, lee owner.x sin comprobar que el dueño exista -> crash. Aquí solo se escribe "activo".
with (obj_hitbox)
{
    if (object_index == obj_hitbox && activo && owner != noone && !instance_exists(owner)) activo = false;
}

// Reiniciar la room (pruebas)
if (keyboard_check_pressed(ord("R")))
>>>>>>> bd2a099f0fe9a40fc91c0ab97a81a6e00d405b96
{
    room_restart();
    exit;
}

// Cambiar de room (pruebas): F1 Room1, F2 Room2, F3 Room_Underdog
if (keyboard_check_pressed(vk_f1)) { room_goto(Room1); exit; }
if (keyboard_check_pressed(vk_f2)) { room_goto(Room2); exit; }
if (keyboard_check_pressed(vk_f3)) { room_goto(Room_Underdog); exit; }
if (keyboard_check_pressed(vk_f4)) { room_goto(Room_Shield); exit; }

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

<<<<<<< HEAD
mec_underdog_inicio();       // primero: bajo tierra bloquea el dash y el gancho normales
mec_gunner_inicio();         // dispara al cursor y cambia de arma (en estilo Gunner)
=======
mec_ud_robot_inicio();         // antes del Underdog: con el robot activo no excava
mec_underdog_inicio();
mec_shield_inicio();         // antes del dash normal: en Shield, Shift es la estampida       // primero: bajo tierra bloquea el dash y el gancho normales
>>>>>>> bd2a099f0fe9a40fc91c0ab97a81a6e00d405b96
mec_doble_salto_inicio();
mec_dash_inicio();
mec_buffer_inicio();
mec_parry_inicio();
mec_gancho_enemigo_inicio();   // antes del gancho normal: si apunta a un enemigo, lo bloquea
mec_gancho_inicio();
