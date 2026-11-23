event_inherited();

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