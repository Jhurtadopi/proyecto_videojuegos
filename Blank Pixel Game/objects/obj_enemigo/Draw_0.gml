// Parpadeo blanco al recibir daño
if (flash_timer > 0) gpu_set_fog(true, c_white, 0, 1);
var _color = (estado == EnemyState.KNOCKED_DOWN) ? c_gray : c_white;     // gris = derribado
var _temblor = 0;
if (aturdido_timer > 0 && estado != EnemyState.KNOCKED_DOWN)
{
    _color = make_color_rgb(255, 225, 140);                              // amarillo = aturdido
    _temblor = (aturdido_timer mod 4 < 2) ? 1 : -1;                      // tiembla
}
draw_sprite_ext(sprite_index, image_index, x + _temblor, y, mirando, 1, 0, _color, 1);
if (flash_timer > 0) gpu_set_fog(false, c_white, 0, 0);

// Barra de vida
var _top = y - sprite_height - 10;
draw_healthbar(x - 16, _top, x + 16, _top + 4, vida / vida_maxima * 100, c_black, c_red, c_lime, 0, true, true);
