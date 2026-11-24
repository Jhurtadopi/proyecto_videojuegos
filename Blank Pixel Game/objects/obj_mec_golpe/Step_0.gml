if (keyboard_check_pressed(ord("Q")))
{
    // Swordmaster -> Underdog -> Gunner -> Base -> Swordmaster
    switch (global.estilo)
    {
        case Estilo.SWORDMASTER: global.estilo = Estilo.UNDERDOG; break;
        case Estilo.UNDERDOG: global.estilo = Estilo.GUNNER; break;
        case Estilo.GUNNER: global.estilo = Estilo.BASE; break;
        default: global.estilo = Estilo.SWORDMASTER; break;
    }
}

// El ultimate congela el mundo con hitstop, así que corre antes de la salida
mec_swordmaster_ultimate_paso();

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
    var _g = golpe_base;
    if (global.estilo == Estilo.SWORDMASTER) _g = mec_swordmaster_elegir_golpe(_jugador);
    else if (global.estilo == Estilo.UNDERDOG) _g = mec_underdog_elegir_golpe(_jugador);

    golpe_hitbox = instance_create_layer(_zona[0], _zona[1], "Instances", obj_hitbox_golpe);
    golpe_hitbox.owner = _jugador;
    golpe_hitbox.damage = _g.danio;
    golpe_hitbox.knockback_y = _g.ky;
    golpe_hitbox.stagger = _g.stagger;
    golpe_hitbox.hitstop = _g.hitstop;
    golpe_hitbox.jugador_vsp = _g.jugador_vsp;

    golpe_actual = _g;
    golpe_kx = _g.kx;
    golpe_nombre = _g.nombre;
    golpe_nombre_timer = 30;
}

// Cada golpe puede tener su propia zona (Swordmaster); si no, usa la del parry
var _zona_golpe = mec_golpe_zona(_jugador, _mirando, golpe_actual);
if (!is_undefined(_zona_golpe)) _zona = _zona_golpe;
golpe_zona = _zona;

// El hitbox sigue al jugador y cubre exactamente la zona del golpe
golpe_hitbox.x = _zona[0];
golpe_hitbox.y = _zona[1];
golpe_hitbox.image_xscale = (_zona[2] - _zona[0]) / sprite_get_width(spr_golpe_hitbox);
golpe_hitbox.image_yscale = (_zona[3] - _zona[1]) / sprite_get_height(spr_golpe_hitbox);
// Golpes direccionales (corte aéreo): A/D al golpear decide hacia dónde sale el enemigo
var _kx = golpe_kx * _mirando;
if (is_struct(golpe_actual) && variable_struct_exists(golpe_actual, "kx_input"))
{
    var _in = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    if (_in != 0) _kx = _in * golpe_actual.kx_input;
}
golpe_hitbox.knockback_x = _kx;
