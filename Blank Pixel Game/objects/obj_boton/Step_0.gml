t++;
brillo = max(0, brillo - 1);
if (pulsado && !nivel_canal_activo(canal)) pulsado = false;      // su grúa (ascensor) volvió: se rearma
if (!pulsado && nivel_canal_activo(canal)) pulsado = true;       // canal recuperado de un checkpoint
if (!pulsado)
{
    var _j = nivel_jugador();
    var _pisa = (_j != noone && place_meeting(x, y - 2, _j));
    var _golpe = place_meeting(x, y, obj_hitbox_golpe);
    if (_pisa || _golpe)
    {
        pulsado = true;
        brillo = 30;
        nivel_activar_canal(canal);
        with (obj_camara) aplicar_temblor(3, 10);
        with (obj_controladores) aplicar_hitstop(4);
    }
}
image_index = pulsado ? 1 : 0;
