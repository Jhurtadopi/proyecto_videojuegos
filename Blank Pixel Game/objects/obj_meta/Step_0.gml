t++;
image_index = (t div 12) mod 2;
var _j = nivel_jugador();
if (!terminado && _j != noone && place_meeting(x, y, _j))
{
    terminado = true;
    espera = 150;
    global.nivel_cp = undefined;
    with (obj_nivel) t_final = current_time - t_inicio;
    with (obj_camara) aplicar_temblor(4, 20);
}
if (terminado)
{
    espera--;
    if (espera <= 0)
    {
        var _dest = siguiente;
        if (_dest == -1 || !room_exists(_dest)) _dest = room_next(room);
        if (_dest != -1 && room_exists(_dest)) room_goto(_dest);
        else room_restart();
    }
}
