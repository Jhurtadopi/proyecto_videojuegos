// ==============================
// MECÁNICAS DEL JUGADOR (componente)
// Agrega mecánicas a obj_jugador SIN modificar su código.
//   Begin Step: corre antes del Step de obj_jugador (preparar saltos, iniciar acciones).
//   End Step:   corre después (corregir el movimiento que hizo obj_jugador).
// Cada mecánica vive en su script scr_mec_*.
// ==============================

jugador = noone;
mirando = 1;            // 1 derecha, -1 izquierda
x_inicio = 0;           // x del jugador al empezar el frame
y_inicio = 0;           // y del jugador al empezar el frame
en_hitstop = false;

depth = -100;           // dibujar por encima del jugador

nombres_estado = ["NORMAL", "ATTACK", "HURT", "KNOCKDOWN"];

mec_doble_salto_crear();
mec_dash_crear();
mec_parry_crear();
mec_gancho_crear();
mec_animacion_crear();
mec_buffer_crear();
mec_gancho_enemigo_crear();
mec_pared_crear();
mec_underdog_crear();
mec_shield_crear();
mec_gunner_crear();
mec_ud_robot_crear();          // ultimate del Underdog (robot)
mec_enemigos_anim_crear();     // sprites de los enemigos (scr_mec_animacion_enemigos)

// Cámara con temblor (objeto propio): se crea si la room no tiene uno
if (!instance_exists(obj_camara)) instance_create_layer(0, 0, "Instances", obj_camara);

// El jugador apunta el gancho con un cursor propio en vez del puntero del sistema
window_set_cursor(cr_none);
