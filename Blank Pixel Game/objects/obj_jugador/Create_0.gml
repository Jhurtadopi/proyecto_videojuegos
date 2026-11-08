// ==============================
// MOVIMIENTO
// ==============================

velocidad_normal = 3;
velocidad_correr = 5;
velocidad_actual = velocidad_normal;

hsp = 0;
vsp = 0;

gravedad = 0.5;
fuerza_salto = -10;

// ==============================
// COYOTE TIME
// ==============================

coyote_max = 8;
coyote_timer = 0;

// ==============================
// JUMP BUFFER
// ==============================

buffer_max = 8;
buffer_timer = 0;

// ==============================
// SALTO VARIABLE
// ==============================

salto_doble = 12;

// ==============================
// ESTADOS
// ==============================

corriendo = false;
agachado = false;
en_suelo = false;

estado = PlayerState.NORMAL;
estado_anterior = PlayerState.NORMAL;

puede_moverse = true;
puede_atacar = true;

// VIDA
vida = 100;
vida_maxima = 100;

// ESTADO
estado = PlayerState.NORMAL;
estado_anterior = PlayerState.NORMAL;

// CONTROL
puede_moverse = true;
puede_atacar = true;

// CONTROLADOR (garantiza que global.hitstop_timer exista)
if (!instance_exists(obj_controladores))
{
    instance_create_layer(0, 0, "Instances", obj_controladores);
}

// HURTBOX
hurtbox = instance_create_layer(
    x,
    y,
    "Instances",
    obj_hurtbox
);

hurtbox.owner = id;

cambiar_estado = function(_nuevo_estado)
{
    estado_anterior = estado;
    estado = _nuevo_estado;
};

recibir_impacto = function(
    _damage,
    _knockback_x,
    _knockback_y,
    _stagger
)
{
    if (estado == PlayerState.KNOCKDOWN)
        return;

    vida -= _damage;

    cambiar_estado(PlayerState.HURT);

    hsp = _knockback_x;
    vsp = _knockback_y;

    if (vida <= 0)
    {
        if (instance_exists(hurtbox)) instance_destroy(hurtbox);
        instance_destroy();
    }
};