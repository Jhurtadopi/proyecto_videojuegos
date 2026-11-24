event_inherited();

if (global.hitstop_timer > 0) exit;
if (!instance_exists(obj_jugador)) exit;

atq_golpe_t = max(0, atq_golpe_t - 1);

// Aturdido (parry, golpes, escudo clavado): pierde el ataque que estaba preparando
if (aturdido_timer > 0 || estado != EnemyState.NORMAL)
{
    atq_prep = 0;
    exit;
}

var _j = instance_find(obj_jugador, 0);
var _dx = _j.x - x;
atq_cooldown = max(0, atq_cooldown - 1);

if (atq_prep > 0)
{
    atq_prep--;
    if (atq_prep == 0)
    {
        var _h = instance_create_layer(x + mirando * 28, y - 24, "Instances", obj_hitbox);
        _h.owner = id;
        _h.damage = 10;
        _h.knockback_x = mirando * 5;
        _h.knockback_y = -3;
        _h.stagger = 15;
        _h.image_xscale = 1.2;
        _h.image_yscale = 1.5;
        _h.visible = false;
        _h.alarm[0] = 6;            // el golpe dura 6 frames
        atq_golpe_t = 8;
        atq_cooldown = atq_cooldown_max;
    }
}
else if (atq_cooldown == 0 && abs(_dx) <= atq_alcance && abs(_j.y - y) < 40)
{
    atq_prep = atq_prep_max;
}
else if (abs(_dx) > atq_alcance - 10 && abs(_dx) < 400 && lanzable)
{
    // Camina hacia el jugador
    var _paso = sign(_dx) * vel_caminar;
    if (!place_meeting(x + _paso, y, obj_solid)) x += _paso;
}
