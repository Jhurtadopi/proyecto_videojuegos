// Enemigo base (padre de todos los enemigos). Por sí solo es un saco de pruebas.
equipo = "enemigo";

vida_maxima = 40;
vida = vida_maxima;

estado = EnemyState.NORMAL;
mirando = -1;
flash_timer = 0;

// HURTBOX del tamaño del sprite
hurtbox = instance_create_layer(x, y, "Instances", obj_hurtbox);
hurtbox.owner = id;
hurtbox.image_xscale = sprite_width / 32;
hurtbox.image_yscale = sprite_height / 64;

recibir_impacto = function(_damage, _knockback_x, _knockback_y, _stagger)
{
    vida -= _damage;
    flash_timer = 6;

    if (vida <= 0)
    {
        if (instance_exists(hurtbox)) instance_destroy(hurtbox);
        instance_destroy();
    }
};
