if (global.hitstop_timer > 0) exit;

ang -= giro * dir;

var _j = noone;
if (instance_exists(dueno)) _j = dueno.jugador;
if (!instance_exists(_j))
{
    instance_destroy();
    exit;
}

switch (estado)
{
    case 0:     // VOLANDO
        var _tx, _ty;
        if (instance_exists(objetivo))
        {
            _tx = (objetivo.bbox_left + objetivo.bbox_right) / 2;
            _ty = (objetivo.bbox_top + objetivo.bbox_bottom) / 2;
        }
        else
        {
            _tx = x + dir * vel;
            _ty = y;
        }

        var _d = point_distance(x, y, _tx, _ty);
        var _dirm = point_direction(x, y, _tx, _ty);
        x += lengthdir_x(min(vel, _d), _dirm);
        y += lengthdir_y(min(vel, _d), _dirm);
        distancia += vel;

        // Se clava en el primer enemigo que toque
        var _e = instance_place(x, y, obj_enemigo);
        if (_e == noone) _e = collision_circle(x, y, 14, obj_enemigo, false, true);
        if (_e != noone && _e.visible)
        {
            objetivo = _e;
            estado = 1;
            clavado_timer = clavado_max;
            off_x = x - _e.x;
            off_y = y - _e.y;
            var _di = danio_impacto;
            var _st = stagger_tick * 2;
            with (_e) recibir_impacto(_di, 0, 0, _st);
            with (obj_controladores) aplicar_hitstop(3);
            with (obj_camara) aplicar_temblor(3, 8);
            if (instance_exists(dueno)) with (dueno) mec_shield_chispas(other.x, other.y, make_color_rgb(255, 200, 80), 8, 14);
        }
        else if (place_meeting(x, y, obj_solid) || distancia >= distancia_max)
        {
            estado = 2;
        }
    break;

    case 1:     // CLAVADO
        if (!instance_exists(objetivo))
        {
            estado = 2;
            break;
        }
        x = objetivo.x + off_x;
        y = objetivo.y + off_y;
        objetivo.aturdido_timer = max(objetivo.aturdido_timer, 10);
        clavado_timer--;

        if (clavado_timer mod tick_cada == 0)
        {
            var _dt = danio_tick;
            var _stt = stagger_tick;
            with (objetivo) recibir_impacto(_dt, 0, 0, _stt);
            if (instance_exists(dueno)) with (dueno) mec_shield_chispas(other.x, other.y, make_color_rgb(255, 200, 80), 4, 10);
        }
        if (clavado_timer <= 0) estado = 2;
    break;

    case 2:     // VOLVIENDO a la mano
        var _hx = _j.x;
        var _hy = _j.y - 40;
        var _dv = point_distance(x, y, _hx, _hy);
        if (_dv <= vel_vuelta + 4)
        {
            if (instance_exists(dueno))
            {
                dueno.sh_tiene_escudo = true;
                dueno.sh_escudo_inst = noone;
            }
            instance_destroy();
            exit;
        }
        var _dirv = point_direction(x, y, _hx, _hy);
        x += lengthdir_x(vel_vuelta, _dirv);
        y += lengthdir_y(vel_vuelta, _dirv);
    break;
}
