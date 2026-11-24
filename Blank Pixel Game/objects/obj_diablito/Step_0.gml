event_inherited();
if (variable_global_exists("hitstop_timer") && global.hitstop_timer > 0) exit;
mask_index = spr_base;
atk_cd = max(0, atk_cd - 1);

var _j = nivel_jugador();
var _suelo = place_meeting(x, y + 1, obj_solid);
var _libre = (estado == EnemyState.NORMAL && aturdido_timer <= 0 && _suelo);
if (atk_t > 0)
{
    atk_t--;
    if (atk_t == 8) dem_golpe(-4, 28, -30, 0, 5, 3, -2, 6, 4);
}
else if (_libre && atk_cd == 0 && _j != noone && abs(_j.x - x) < 34 && abs(_j.y - y) < 40)
{
    mirando = (_j.x >= x) ? 1 : -1;
    atk_t = 16;
    atk_cd = 70;
}
caminar_habilitado = (atk_t == 0);

// Animación (si faltan los sprites de Higgsfield usa el provisional)
var _s = spr.idle, _i = (current_time div 160) mod 2;
if (!_suelo || estado == EnemyState.AIRBORNE) { _s = spr.aire; _i = 0; }
else if (atk_t > 0) { _s = spr.ataque; _i = (atk_t > 8) ? 0 : 1; }
else if (abs(x - prev_x) > 0.3) { _s = spr.correr; _i = (current_time div 90) mod 2; }
if (_s == -1) _s = spr.idle;
if (_s == -1) { _s = spr_base; _i = 0; }
sprite_index = _s;
image_index = min(_i, sprite_get_number(_s) - 1);
image_speed = 0;
prev_x = x;
