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

    hsp = _knockback_x;
    vsp = _knockback_y;
    estampado = (_knockback_y >= impacto_estampar);

    if (_knockback_y != 0) estado = EnemyState.AIRBORNE;
};
