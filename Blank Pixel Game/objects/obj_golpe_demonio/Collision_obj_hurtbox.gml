if (!activo) exit;
var _t = other.owner;
if (_t == noone || !instance_exists(_t) || _t == owner) exit;
if (_t.object_index != obj_jugador) exit;
if (nivel_invulnerable()) exit;
if (array_contains(golpeados, _t)) exit;
array_push(golpeados, _t);

// Guardia frontal (Shield): mismo criterio que obj_hitbox
if (variable_instance_exists(_t, "bloqueando") && _t.bloqueando && variable_instance_exists(_t, "mirando")
    && instance_exists(owner) && _t.mirando == sign(owner.x - _t.x))
{
    _t.bloqueo_golpes_recibidos++;
    with (obj_controladores) aplicar_hitstop(3);
    if (_t.bloqueo_golpes_recibidos >= _t.bloqueo_resistencia)
    {
        _t.bloqueando = false;
        _t.bloqueo_golpes_recibidos = 0;
        _t.bloqueo_recovery_timer = _t.bloqueo_recovery;
    }
    exit;
}

var _d = damage, _kx = knockback_x, _ky = knockback_y, _st = stagger;
with (_t) recibir_impacto(_d, _kx, _ky, _st);
with (obj_controladores) aplicar_hitstop(4);
with (obj_camara) aplicar_temblor(3, 8);
if (instance_exists(owner) && variable_instance_exists(owner, "conecto")) owner.conecto = true;
