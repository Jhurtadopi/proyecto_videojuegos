// La animación corre siempre (también en hitstop, para congelarla)
mec_animacion_fin();
mec_enemigos_animacion();       // sprites de los enemigos según su estado (también en hitstop, congelados)

if (jugador == noone || en_hitstop || !instance_exists(jugador)) exit;

mec_doble_salto_fin();
mec_dash_fin();
mec_parry_fin();
mec_gancho_fin();
mec_gancho_enemigo_fin();
mec_pared_fin();
mec_underdog_fin();
mec_ud_robot_fin();
mec_shield_fin();
// Retroceso del Gunner: scr_mec_gunner (de otro colaborador) lo aplica con "_j.x +=" y mete al jugador en
// las paredes. Se le quita antes de su End Step y se aplica aquí con colisión (misma caída: x0.6).
var _ret = gn_retroceso;
gn_retroceso = 0;
mec_gunner_fin();
if (_ret != 0)
{
    mec_mover_hasta_x(jugador, jugador.x + _ret);
    _ret *= 0.6;
    if (abs(_ret) < 0.2) _ret = 0;
}
if (gn_retroceso == 0) gn_retroceso = _ret;
mec_plataformas_fin();        // el jugador viaja con las plataformas móviles (después de todo lo demás)

// Estampada del Swordmaster: caída rápida e impacto (vive en obj_mec_golpe)
var _yi = y_inicio;
var _jg = jugador;
with (obj_mec_golpe) mec_swordmaster_picado_fin(_jg, _yi);
