// Golpe cuerpo a cuerpo del jugador. Usa el mismo click y la misma zona que el parry:
// mientras la ventana de scr_mec_parry está abierta, mantiene un hitbox que daña enemigos.
// Es un objeto aparte para no editar obj_mecanicas_jugador ni scr_mec_parry.

golpe_danio = 10;           // vida que quita a cada enemigo alcanzado
golpe_knockback_x = 5;      // empuje horizontal hacia donde mira el jugador
golpe_knockback_y = -3;     // empuje vertical (negativo = hacia arriba)
golpe_stagger = 10;         // aturdimiento que se pasa a recibir_impacto
golpe_hitstop = 5;          // frames de congelamiento al acertar

golpe_hitbox = noone;       // hitbox activo del golpe actual
