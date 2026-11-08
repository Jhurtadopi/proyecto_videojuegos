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
en_hitstop = false;

depth = -100;           // dibujar por encima del jugador

nombres_estado = ["NORMAL", "ATTACK", "HURT", "KNOCKDOWN"];

mec_doble_salto_crear();
mec_dash_crear();
mec_parry_crear();
