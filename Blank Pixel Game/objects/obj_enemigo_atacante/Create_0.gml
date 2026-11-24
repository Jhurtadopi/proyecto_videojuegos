event_inherited();

// Enemigo de prueba para el parry del Shield: se acerca, avisa con "!" y golpea cuerpo a cuerpo.
// Su golpe es un obj_hitbox con owner = este enemigo (necesario para el bloqueo de obj_hitbox).
vida_maxima = 60;
vida = vida_maxima;

atq_alcance = 70;           // px a los que empieza a atacar
atq_prep_max = 36;          // frames de aviso antes del golpe (la ventana para hacer parry)
atq_prep = 0;
atq_cooldown_max = 70;
atq_cooldown = 40;
atq_golpe_t = 0;            // frames que se dibuja el tajo
vel_caminar = 1.2;
