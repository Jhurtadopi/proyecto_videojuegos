event_inherited();   // datos de obj_hitbox: owner, damage, knockback, stagger, activo

// Hitbox del golpe cuerpo a cuerpo. La crea y la mueve obj_mec_golpe.
hitstop = 5;
golpeados = [];      // cada objetivo recibe un solo impacto por golpe
visible = false;     // obj_mecanicas_jugador ya dibuja la zona del golpe
