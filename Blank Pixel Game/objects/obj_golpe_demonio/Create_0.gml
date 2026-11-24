// Golpe del jefe demonio y de los diablitos (hijo de obj_hitbox): SOLO daña al jugador
// (las hitboxes normales también dañarían a los diablitos). Respeta la guardia frontal del Shield
// igual que obj_hitbox. No se destruye al pegar: dura "frames" y cada objetivo recibe un impacto.
event_inherited();
dueno = noone;
zona = [0, 0, 0, 0];
frames = 10;
golpeados = [];
visible = false;
