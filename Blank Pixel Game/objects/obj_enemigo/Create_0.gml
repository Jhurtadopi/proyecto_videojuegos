// Enemigo base (padre de todos los enemigos). Por sí solo es un saco de pruebas.
equipo = "enemigo";

vida_maxima = 40;
vida = vida_maxima;

estado = EnemyState.NORMAL;
aturdido_timer = 0;         // > 0: aturdido por un golpe (no ataca); lo llena el stagger

// LÍMITE DE JUGGLE: los golpes que lo mantienen en el aire pierden fuerza si se repiten
juggle_cuenta = 0;          // golpes hacia arriba recibidos sin tocar el suelo
juggle_libres = 4;          // los primeros N golpes aéreos levantan con fuerza completa
juggle_decaimiento = 0.25;  // cada golpe extra levanta un 25 % menos (al 8.º ya no levanta)

// CONEXIÓN CON UNDERDOG: tras ser estampado queda una ventana en la que el estilo Underdog
// (aún no implementado) podrá arrastrarlo bajo tierra. Leer conexion_underdog_timer > 0.
conexion_underdog_frames = 45;
conexion_underdog_timer = 0;
mirando = -1;
flash_timer = 0;

// HURTBOX del tamaño del sprite
hurtbox = instance_create_layer(x, y, "Instances", obj_hurtbox);
hurtbox.owner = id;
hurtbox.image_xscale = sprite_width / 32;
hurtbox.image_yscale = sprite_height / 64;

// REACCIÓN A LOS GOLPES
lanzable = true;            // false = no se mueve al recibir golpes (ej. torretas)
hsp = 0;
vsp = 0;
gravedad_enemigo = 0.5;     // igual a la del jugador para que suban juntos al lanzarlos
vsp_max = 20;               // velocidad máxima de caída
friccion_suelo = 0.8;       // pérdida de velocidad en X por frame en el suelo
impacto_estampar = 10;      // desde esta velocidad hacia abajo el golpe estampa
danio_estampado = 10;       // daño extra al chocar contra el suelo
derribado_frames = 45;      // frames en el suelo tras ser estampado
derribado_timer = 0;
estampado = false;

aplicar_danio = function(_damage)
{
    vida -= _damage;
    flash_timer = 6;

    if (vida <= 0)
    {
        if (instance_exists(hurtbox)) instance_destroy(hurtbox);
        instance_destroy();
    }
};

// Peso, combos y estilos
peso = 1.0;                     // 1.0 = ligero, 2.0 = mediano, 3.5+ = pesado
resistencia_knockback = 1.0;    // Reduce desplazamiento/lanzamiento según peso
poise_max = 20;                 // Umbral de desestabilización (stagger acumulado)
poise_actual = 0;
tiempo_desestabilizado = 0;
duracion_desestabilizado = 50;

combo_hits = 0;
combo_ventana_max = 45;
combo_ventana = 0;
estilo_favorecido = "BASE";     // "SWORDMASTER", "BASE", "GUNNER"
mult_estilo_danio = 1.3;
mult_estilo_stagger = 1.4;

recibir_impacto = function(_damage, _knockback_x, _knockback_y, _stagger)
{
    aplicar_danio(_damage);
    aturdido_timer = max(aturdido_timer, _stagger);

    if (vida <= 0 || !lanzable) return;

    // Golpes que lo mantienen arriba estando ya en el aire: se van debilitando
    if (_knockback_y < 0 && estado == EnemyState.AIRBORNE)
    {
        juggle_cuenta++;
        var _factor = clamp(1 - max(0, juggle_cuenta - juggle_libres) * juggle_decaimiento, 0, 1);
        _knockback_y *= _factor;
    }
	
    // Beneficia el estilo que encaja con el enemigo
    if (global.estilo == estilo_favorecido)
    {
        _mult_d = mult_estilo_danio;
        _mult_s = mult_estilo_stagger;
    }

    hsp = _knockback_x;
    vsp = _knockback_y;
    estampado = (_knockback_y >= impacto_estampar);
	if (_knockback_y != 0) estado = EnemyState.AIRBORNE;
	
	// Contador de combo y bonus por combos largos/potentes
	combo_hits += 1;
    combo_ventana = combo_ventana_max;
    var _bonus_combo_largo = 1.0 + max(0, combo_hits - 3) * 0.1;
};

// CAMINATA BASE
vel_caminar = 1;          // 0 = no camina (ej. saco de pruebas o torreta estática)
caminar_habilitado = true;  // Permite apagar la caminata temporalmente si lo necesitas
// PATRULLA Y DETECCIÓN DEL JUGADOR
dir_patrulla = -1;          // -1 = izquierda, 1 = derecha
rango_deteccion = 180;      // Distancia en píxeles para empezar a perseguir al jugador
// DETECCION DIRECCIONAL DEL JUGADOR
var _jugador = instance_find(obj_jugador, 0);

evitar_bordes = true;       // Evita caer al vacío al patrullar o perseguir
margen_borde = 8;           // Píxeles por delante para comprobar suelo (obj_solid)

persecucion_duracion = 60; // Duración del ciclo de persecución en frames (ej. 1 seg a 60 FPS)
persecucion_timer = 0;    // > 0 mientras el ciclo de persecución está activo