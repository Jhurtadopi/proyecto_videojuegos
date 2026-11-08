// Reiniciar la room (pruebas)
if (keyboard_check_pressed(ord("R")))
{
    room_restart();
    exit;
}

jugador = instance_exists(obj_jugador) ? instance_find(obj_jugador, 0) : noone;

// obj_jugador no se mueve durante el hitstop; las mecánicas tampoco
en_hitstop = variable_global_exists("hitstop_timer") && global.hitstop_timer > 0;

if (jugador == noone || en_hitstop) exit;

var _dir = keyboard_check(ord("D")) - keyboard_check(ord("A"));
if (_dir != 0) mirando = _dir;

x_inicio = jugador.x;
y_inicio = jugador.y;

mec_doble_salto_inicio();
mec_dash_inicio();
mec_parry_inicio();
mec_gancho_inicio();
