global.hitstop_timer = 0;

aplicar_hitstop = function(_frames)
{
    global.hitstop_timer = max(
        global.hitstop_timer,
        _frames
    );
};

cambiando_room = false;
delay_cambio = 30;        // Pequeña pausa en frames tras matar al último enemigo (opcional)
timer_cambio = delay_cambio;
room_destino = noone;     // Si es noone, irá a room_next(room); si le asignas una room, irá a esa