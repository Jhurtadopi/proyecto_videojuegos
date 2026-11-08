event_inherited();   // datos de obj_hitbox: owner, damage, knockback, stagger, activo

// Proyectil: un hitbox que se mueve. El parry lo devuelve cambiando owner y equipo.
equipo = "enemigo";     // "enemigo" o "jugador" (al reflejarlo)

vx = 0;
vy = 0;

damage = 10;
knockback_y = -2;
stagger = 5;

reflejado = false;
vida_frames = 300;
