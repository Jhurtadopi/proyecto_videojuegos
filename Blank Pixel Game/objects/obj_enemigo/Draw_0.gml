// Parpadeo blanco al recibir daño
if (flash_timer > 0) gpu_set_fog(true, c_white, 0, 1);
draw_sprite_ext(sprite_index, image_index, x, y, mirando, 1, 0, c_white, 1);
if (flash_timer > 0) gpu_set_fog(false, c_white, 0, 0);

// Barra de vida
var _top = y - sprite_height - 10;
draw_healthbar(x - 16, _top, x + 16, _top + 4, vida / vida_maxima * 100, c_black, c_red, c_lime, 0, true, true);
