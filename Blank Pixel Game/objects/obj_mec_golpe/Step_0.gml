if (global.hitstop_timer > 0) exit;

// Corre en Step: Begin Step ya inició el golpe y End Step todavía no avanzó su timer
var _jugador = noone;
var _mirando = 1;
var _activo = false;
var _zona = undefined;

with (obj_mecanicas_jugador)
{
    _jugador = jugador;
    _mirando = mirando;

    if (instance_exists(jugador) && mec_parry_en_ventana())
    {
        _activo = true;
        _zona = mec_parry_zona();
    }
}

if (!_activo)
{
    if (instance_exists(golpe_hitbox)) instance_destroy(golpe_hitbox);
    golpe_hitbox = noone;
    exit;
}

if (!instance_exists(golpe_hitbox))
{
    golpe_hitbox = instance_create_layer(_zona[0], _zona[1], "Instances", obj_hitbox_golpe);
    golpe_hitbox.owner = _jugador;
    golpe_hitbox.damage = golpe_danio;
    golpe_hitbox.knockback_y = golpe_knockback_y;
    golpe_hitbox.stagger = golpe_stagger;
    golpe_hitbox.hitstop = golpe_hitstop;
}

// El hitbox sigue al jugador y cubre exactamente la zona del golpe
golpe_hitbox.x = _zona[0];
golpe_hitbox.y = _zona[1];
golpe_hitbox.image_xscale = (_zona[2] - _zona[0]) / sprite_get_width(spr_golpe_hitbox);
golpe_hitbox.image_yscale = (_zona[3] - _zona[1]) / sprite_get_height(spr_golpe_hitbox);
golpe_hitbox.knockback_x = golpe_knockback_x * _mirando;
