// Golpe cuerpo a cuerpo del jugador. Usa el mismo click y la misma zona que el parry:
// mientras la ventana de scr_mec_parry está abierta, mantiene un hitbox que daña enemigos.
// Es un objeto aparte para no editar obj_mecanicas_jugador ni scr_mec_parry.

// Golpe sin estilo. kx se multiplica por la dirección en que mira el jugador, ky negativo
// es hacia arriba y jugador_vsp se aplica al jugador solo si conecta (undefined = no lo mueve).
golpe_base = { nombre: "Golpe", danio: 10, kx: 5, ky: -3, stagger: 10, hitstop: 5, jugador_vsp: undefined };

golpe_hitbox = noone;       // hitbox activo del golpe actual
golpe_actual = undefined;   // datos del golpe en curso
golpe_zona = undefined;     // zona real del último golpe [x1, y1, x2, y2] (la dibuja obj_mecanicas_jugador)
golpe_kx = 0;               // empuje horizontal del golpe actual
golpe_nombre = "";          // nombre del último golpe, para el HUD
golpe_nombre_timer = 0;     // frames que se sigue mostrando

// Estilo inicial: la room de pruebas del Underdog empieza en ese estilo
global.estilo = (room == Room_Underdog) ? Estilo.UNDERDOG : ((room == Room_Shield) ? Estilo.SHIELD : Estilo.SWORDMASTER);
mec_swordmaster_crear();
