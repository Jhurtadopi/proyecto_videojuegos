var _j = nivel_jugador();
if (_j != noone && !nivel_invulnerable() && place_meeting(x, y, _j))
{
    with (obj_camara) aplicar_temblor(5, 12);
    nivel_reaparecer(danio);
}

// Enemigos que caen o son lanzados a los pinchos
with (obj_enemigo)
{
    if (!lanzable || !visible) continue;
    if (!variable_instance_exists(id, "nv_pincho_cd")) nv_pincho_cd = 0;
    if (nv_pincho_cd > 0) { nv_pincho_cd--; continue; }
    if (place_meeting(x, y, other))
    {
        nv_pincho_cd = 40;
        recibir_impacto(12, 0, -9, 30);
    }
}
