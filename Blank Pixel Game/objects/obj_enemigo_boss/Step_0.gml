event_inherited();

//DISPARO
if (global.hitstop_timer > 0) exit;
if (!instance_exists(obj_jugador)) exit;
if (aturdido_timer > 0) exit;   // aturdida: no dispara (el contador se pausa)

disparo_timer--;

if (disparo_timer <= 0)
{
    disparo_timer = disparo_intervalo;

    var _j = instance_nearest(x, y, obj_jugador);
    if (point_distance(x, y, _j.x, _j.y) > rango) exit;

    var _sx = x + mirando * 16;
    var _sy = y - sprite_height / 2;
    var _dir = point_direction(_sx, _sy, _j.x, _j.y - _j.sprite_height / 2);

    var _p = instance_create_layer(_sx, _sy, "Instances", obj_proyectil);
    _p.owner = id;
    _p.equipo = equipo;
    _p.vx = lengthdir_x(proyectil_velocidad, _dir);
    _p.vy = lengthdir_y(proyectil_velocidad, _dir);
}

// SISTEMA DE RECUPERACION DE GUARDIA

if (bloqueo_recovery_timer > 0)
{
    bloqueo_recovery_timer--;
}

// SISTEMA DE BLOQUEO ACTIVO

if (bloqueando)
{
    bloqueo_timer--;

    if (bloqueo_timer <= 0)
    {
        bloqueando = false;
        bloqueo_golpes_recibidos = 0;
    }
}

// ACTIVACION AUTOMATICA DE GUARDIA

if (puede_bloquear
&& !bloqueando
&& bloqueo_recovery_timer <= 0
&& estado == EnemyState.NORMAL)
{
    bloqueo_intervalo_timer--;

    if (bloqueo_intervalo_timer <= 0)
    {
        bloqueando = true;
        bloqueo_timer = bloqueo_duracion;
        bloqueo_intervalo_timer = bloqueo_intervalo;
    }
}