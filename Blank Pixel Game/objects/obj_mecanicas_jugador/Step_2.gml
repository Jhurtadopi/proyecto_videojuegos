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

// Estampada del Swordmaster: caída rápida e impacto (vive en obj_mec_golpe)
var _yi = y_inicio;
var _jg = jugador;
with (obj_mec_golpe) mec_swordmaster_picado_fin(_jg, _yi);
