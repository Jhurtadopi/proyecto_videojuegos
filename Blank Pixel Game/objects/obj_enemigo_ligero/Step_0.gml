event_inherited();

if (global.hitstop_timer > 0) exit;
if (!instance_exists(obj_jugador)) exit;

// ==============================
// ATAQUE BÁSICO DEL ENEMIGO
// ==============================

// Buscar al jugador
var _jugador = instance_find(obj_jugador, 0);

// Distancia al jugador
var _distancia = point_distance(
    x, y,
    _jugador.x, _jugador.y
);

// Cooldown
if (ataque_cooldown_timer > 0) {
    ataque_cooldown_timer--;
}

// ==============================
// INICIAR ATAQUE
// ==============================

if (!ataque_enemigo_activo
&& ataque_cooldown_timer <= 0
&& _distancia <= ataque_alcance && estado==EnemyState.NORMAL) {
	image_blend=c_olive
    ataque_enemigo_activo = true;
	ataque_hitbox_creada = false;
}

// ==============================
// EJECUCIÓN DEL ATAQUE
// ==============================

if (ataque_enemigo_activo) {

    ataque_enemigo_timer--;

    // PREPARACIÓN
    if (!ataque_hitbox_creada
    && ataque_enemigo_timer <= 0) {

        // Crear hitbox del ataque
        var _hitbox = instance_create_layer(
            x + (mirando * 24),
            y - 16,
            "Instances",
            obj_hitbox
        );

        // Propietario
        _hitbox.owner = id;

        // DAÑO
        _hitbox.damage = ataque_danio;

        // EMPUJE
        _hitbox.knockback_x = ataque_knockback_x * mirando;
        _hitbox.knockback_y = ataque_knockback_y;

        // STAGGER
        _hitbox.stagger = ataque_stagger;

        // ACTIVACIÓN
        _hitbox.activo = true;

        // DURACIÓN
        _hitbox.duracion = ataque_duracion;

        ataque_hitbox_creada = true;

        ataque_enemigo_timer = ataque_duracion;
    }

    // FINALIZAR ATAQUE
    else if (ataque_hitbox_creada
    && ataque_enemigo_timer <= 0) {

        ataque_enemigo_activo = false;

        ataque_hitbox_creada = false;

        ataque_cooldown_timer = ataque_cooldown;
    }
}