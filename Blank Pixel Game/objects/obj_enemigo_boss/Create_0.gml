event_inherited();

// IDENTIDAD
tipo_enemigo = "boss";

// VIDA
vida_maxima = 500;
vida = vida_maxima;

// ATAQUES
puede_atacar = true;

ataque_danio = 20;
ataque_stagger = 35;
ataque_knockback_x = 8;
ataque_knockback_y = -4;

ataque_preparacion = 30;
ataque_duracion = 8;
ataque_cooldown = 60;
ataque_alcance = 65;

// DEFENSA
puede_bloquear = true;
bloqueando = false;

bloqueo_resistencia = 5;
bloqueo_golpes_recibidos = 0;

bloqueo_duracion = 120;
bloqueo_recovery = 90;
bloqueo_recovery_timer = 0;

bloqueo_intervalo = 180;
bloqueo_intervalo_timer = 60;

// REFLEJO DE DAÑO
reflejar_danio = false;
porcentaje_reflejo = 0.25;

// CARACTERÍSTICAS
vel_caminar = 1.5;
caminar_habilitado = true;

//DISPARO

disparo_intervalo = 90;     // frames entre disparos
disparo_timer = 60;
proyectil_velocidad = 4;
rango = 900;