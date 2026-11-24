// Escudo de sierra lanzado (estilo Shield). Lo crea mec_shield_inicio con { dueno, objetivo, dir }.
//   0 VOLANDO: va hacia el objetivo (o recto si no hay)
//   1 CLAVADO: se queda en el enemigo girando, lo aturde y le hace daño poco a poco
//   2 VOLVIENDO: regresa a la mano del jugador
if (!variable_instance_exists(id, "dueno")) dueno = noone;
if (!variable_instance_exists(id, "objetivo")) objetivo = noone;
if (!variable_instance_exists(id, "dir")) dir = 1;

estado = 0;
depth = -60;
ang = 0;
giro = 28;                  // grados por frame (sierra girando)
vel = 14;
vel_vuelta = 18;
distancia = 0;
distancia_max = 360;        // sin objetivo: vuela esto y vuelve

danio_impacto = 5;
danio_tick = 2;
tick_cada = 20;             // frames entre cortes mientras está clavado
stagger_tick = 30;
clavado_max = 120;          // frames clavado (2 s)
clavado_timer = 0;
off_x = 0;
off_y = 0;

escala = 0.75;
escudo_spr = asset_get_index("spr" + "_jugador_sh_escudo");     // -1 si aún no existe: se dibuja por código
