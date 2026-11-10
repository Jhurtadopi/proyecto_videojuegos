if (keyboard_check_pressed(ord("Q")))
{
    global.estilo = (global.estilo == Estilo.SWORDMASTER) ? Estilo.BASE : Estilo.SWORDMASTER;
}

if (global.hitstop_timer > 0) exit;

golpe_nombre_timer = max(0, golpe_nombre_timer - 1);

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

mec_swordmaster_paso(_jugador);

if (!_activo)
{
    if (instance_exists(golpe_hitbox)) instance_destroy(golpe_hitbox);
    golpe_hitbox = noone;
    exit;
}

if (!instance_exists(golpe_hitbox))
{
    var _g = (global.estilo == Estilo.SWORDMASTER) ? mec_swordmaster_elegir_golpe(_jugador) : golpe_base;

    golpe_hitbox = instance_create_layer(_zona[0], _zona[1], "Instances", obj_hitbox_golpe);
    golpe_hitbox.owner = _jugador;
    golpe_hitbox.damage = _g.danio;
    golpe_hitbox.knockback_y = _g.ky;
    golpe_hitbox.stagger = _g.stagger;
    golpe_hitbox.hitstop = _g.hitstop;
    golpe_hitbox.jugador_vsp = _g.jugador_vsp;

    golpe_kx = _g.kx;
    golpe_nombre = _g.nombre;
    golpe_nombre_timer = 30;
}

// El hitbox sigue al jugador y cubre exactamente la zona del golpe
golpe_hitbox.x = _zona[0];
golpe_hitbox.y = _zona[1];
golpe_hitbox.image_xscale = (_zona[2] - _zona[0]) / sprite_get_width(spr_golpe_hitbox);
golpe_hitbox.image_yscale = (_zona[3] - _zona[1]) / sprite_get_height(spr_golpe_hitbox);
golpe_hitbox.knockback_x = golpe_kx * _mirando;
