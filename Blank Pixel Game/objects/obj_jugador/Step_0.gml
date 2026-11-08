if (global.hitstop_timer > 0)
{
    exit;
}

switch (estado)
{
    case PlayerState.NORMAL:

        // Aquí funciona el movimiento habitual.
        puede_moverse = true;
        puede_atacar = true;

    break;


    case PlayerState.ATTACK:

        // Durante el ataque.
        puede_moverse = false;
        puede_atacar = false;

    break;


    case PlayerState.HURT:

        // El personaje recibió daño.
        puede_moverse = false;
        puede_atacar = false;

    break;


    case PlayerState.KNOCKDOWN:

        // El personaje fue derribado.
        puede_moverse = false;
        puede_atacar = false;

    break;
}

if (instance_exists(hurtbox))
{
    hurtbox.x = x;
    hurtbox.y = y;
}

// Movimiento horizontal
var derecha = keyboard_check(ord("D"));
var izquierda = keyboard_check(ord("A"));

// Correr
corriendo = keyboard_check(vk_shift);

// Saltar
var salto = keyboard_check_pressed(vk_space);
var salto_doble = keyboard_check(vk_space);

// Agacharse
var agachar = keyboard_check(vk_down);

// Determinar velocidad
velocidad_actual = corriendo ? velocidad_correr : velocidad_normal;

// Determinar dirección
var direccion = derecha - izquierda;

// Agacharse
agachado = agachar && en_suelo;

// Movimiento horizontal
if (agachado)
{
    hsp = direccion * velocidad_normal * 0.5;
}
else
{
    hsp = direccion * velocidad_actual;
}

// Comprobar si está tocando el suelo
en_suelo = place_meeting(x, y + 1, obj_solid);

// Reiniciar coyote time cuando está en el suelo
if (en_suelo)
{
    coyote_timer = coyote_max;
}
else
{
    coyote_timer = max(0, coyote_timer - 1);
}

// Registrar pulsación de salto
if (salto)
{
    buffer_timer = buffer_max;
}
else
{
    buffer_timer = max(0, buffer_timer - 1);
}

// Ejecutar salto
if (buffer_timer > 0 && coyote_timer > 0 && !agachado)
{
    vsp = fuerza_salto;

    buffer_timer = 0;
    coyote_timer = 0;
}

// Reducir altura si se suelta el botón
if (keyboard_check_released(vk_space) && vsp < 0)
{
    vsp *= 0.5;
}

// Aplicar gravedad
vsp += gravedad;

vsp = min(vsp, 12);

if (place_meeting(x + hsp, y, obj_solid))
{
    while (!place_meeting(x + sign(hsp), y, obj_solid))
    {
        x += sign(hsp);
    }

    hsp = 0;
}

x += hsp;

if (place_meeting(x, y + vsp, obj_solid))
{
    while (!place_meeting(x, y + sign(vsp), obj_solid))
    {
        y += sign(vsp);
    }

    vsp = 0;
}

y += vsp;