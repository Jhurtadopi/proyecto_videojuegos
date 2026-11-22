if (!activo) exit;

var _target = other.owner;

if (_target == noone) exit;
if (_target == owner) exit;
if (!instance_exists(_target)) exit;

// DATOS DEL ATAQUE
var _damage = damage;
var _kx = knockback_x;
var _ky = knockback_y;
var _stagger = stagger;

// DETECTAR BLOQUEO
var _bloqueado = false;

if (variable_instance_exists(_target, "bloqueando")
&& variable_instance_exists(_target, "mirando"))
{
    if (_target.bloqueando)
    {
        var _direccion_ataque = sign(owner.x - _target.x);

        // Solo bloquea ataques frontales
        if (_target.mirando == _direccion_ataque)
        {
            _bloqueado = true;
        }
    }
}

// SI EL ATAQUE ES BLOQUEADO
if (_bloqueado)
{
    // Contabilizar el golpe
    _target.bloqueo_golpes_recibidos++;

    // HITSTOP
    with (obj_controladores)
    {
        aplicar_hitstop(3);
    }

    // ROMPER GUARDIA
    if (_target.bloqueo_golpes_recibidos >= _target.bloqueo_resistencia)
    {
        _target.bloqueando = false;
        _target.bloqueo_golpes_recibidos = 0;
        _target.bloqueo_recovery_timer = _target.bloqueo_recovery;
    }

    instance_destroy();
    exit;
}

// SI NO BLOQUEA, RECIBE EL ATAQUE NORMAL
with (_target)
{
    recibir_impacto(_damage, _kx, _ky, _stagger);
}

// HITSTOP
with (obj_controladores)
{
    aplicar_hitstop(5);
}

instance_destroy();