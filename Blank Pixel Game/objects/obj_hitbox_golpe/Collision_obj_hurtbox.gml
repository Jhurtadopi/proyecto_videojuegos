// Reemplaza la colisión heredada de obj_hitbox: el hitbox no se destruye al primer
// impacto para poder alcanzar a varios enemigos, pero a cada uno solo una vez por golpe.
if (!activo) exit;

var _target = other.owner;

if (_target == noone) exit;
if (!instance_exists(_target)) exit;
if (_target == owner) exit;
if (array_contains(golpeados, _target)) exit;

array_push(golpeados, _target);

var _damage = damage;
var _kx = knockback_x;
var _ky = knockback_y;
var _stagger = stagger;
var _frames = hitstop;

with (_target)
{
    recibir_impacto(_damage, _kx, _ky, _stagger);
}

if (!is_undefined(jugador_vsp) && instance_exists(owner))
{
    owner.vsp = jugador_vsp;
}

with (obj_controladores)
{
    aplicar_hitstop(_frames);
}

// Carga el ultimate del Swordmaster con el daño hecho
with (obj_mec_golpe) mec_swordmaster_ultimate_cargar(_damage);

// Carga la barra del robot del Underdog (y con el robot, el martillo hace rebotar al enemigo)
var _t = _target;
with (obj_mecanicas_jugador) mec_ud_robot_al_golpear(_t, _damage);
