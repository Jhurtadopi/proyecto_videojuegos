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

// Orientarse hacia el jugador
if (_jugador.x > x) {
    mirando = 1;
}
else {
    mirando = -1;
}

// Cooldown
if (ataque_cooldown_timer > 0) {
    ataque_cooldown_timer--;
}

// ==============================
// INICIAR ATAQUE
// ==============================

if (!ataque_enemigo_activo
&& ataque_cooldown_timer <= 0
&& _distancia <= ataque_alcance) {
	image_blend=c_red
    ataque_enemigo_activo = true;
    instance_create_layer(x,y,"instances",obj_hitbox_golpe);
}