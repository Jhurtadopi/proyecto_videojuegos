// Reemplaza la colisión heredada de obj_hitbox para no dañar al propio equipo
// (las balas de una torreta no dañan a otros enemigos; las reflejadas no dañan al jugador).
if (!activo) exit;

var _target = other.owner;

if (_target == noone) exit;
if (!instance_exists(_target)) exit;
if (_target == owner) exit;

var _equipo_target = object_is_ancestor(_target.object_index, obj_enemigo) || _target.object_index == obj_enemigo
    ? "enemigo" : "jugador";

if (_equipo_target == equipo) exit;

var _damage = damage;
var _kx = knockback_x;
var _ky = knockback_y;
var _stagger = stagger;

with (_target)
{
    recibir_impacto(_damage, _kx, _ky, _stagger);
}

with (obj_controladores)
{
    aplicar_hitstop(5);
}

instance_destroy();
