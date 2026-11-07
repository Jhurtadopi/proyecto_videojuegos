if (!activo) exit;

var _target = other.owner;

if (_target == noone) exit;
if (_target == owner) exit;
if (!instance_exists(_target)) exit;

var _damage = damage;
var _kx = knockback_x;
var _ky = knockback_y;
var _stagger = stagger;

with (_target)
{
    recibir_impacto(
        _damage,
        _kx,
        _ky,
        _stagger
    );
}

// HITSTOP
with (obj_game_controller)
{
    aplicar_hitstop(5);
}

instance_destroy();