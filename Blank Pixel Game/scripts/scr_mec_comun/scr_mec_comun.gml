// Utilidades compartidas por las mecánicas del jugador (obj_mecanicas_jugador).
// No modifican el código de obj_jugador: solo leen/escriben sus variables desde fuera.

function mec_en_suelo(_j)
{
    var _r = false;
    with (_j) _r = place_meeting(x, y + 1, obj_solid);
    return _r;
}

// 1 si hay pared justo a la derecha, -1 si está a la izquierda, 0 si no hay
function mec_pared(_j)
{
    var _r = 0;
    with (_j) _r = place_meeting(x + 1, y, obj_solid) - place_meeting(x - 1, y, obj_solid);
    return _r;
}

// Lleva al jugador horizontalmente hasta _x_objetivo sin atravesar sólidos
function mec_mover_hasta_x(_j, _x_objetivo)
{
    with (_j)
    {
        var _paso = sign(_x_objetivo - x);
        var _bloqueado = false;

        while (abs(_x_objetivo - x) >= 1)
        {
            if (place_meeting(x + _paso, y, obj_solid))
            {
                _bloqueado = true;
                break;
            }
            x += _paso;
        }

        if (!_bloqueado && !place_meeting(_x_objetivo, y, obj_solid)) x = _x_objetivo;
    }
}

// Mueve al jugador (_dx, _dy) por pasos sin atravesar sólidos. Cada eje se bloquea por
// separado, así puede deslizarse por una superficie. Devuelve [choco_en_x, choco_en_y].
function mec_mover_con_choque(_j, _dx, _dy)
{
    var _pasos = max(1, ceil(max(abs(_dx), abs(_dy))));
    var _paso_x = _dx / _pasos;
    var _paso_y = _dy / _pasos;
    var _choque_x = false;
    var _choque_y = false;

    with (_j)
    {
        repeat (_pasos)
        {
            if (!_choque_x)
            {
                if (place_meeting(x + _paso_x, y, obj_solid)) _choque_x = true;
                else x += _paso_x;
            }

            if (!_choque_y)
            {
                if (place_meeting(x, y + _paso_y, obj_solid)) _choque_y = true;
                else y += _paso_y;
            }
        }
    }

    return [_choque_x, _choque_y];
}

// Enemigo más cercano en la dirección _dir (1 / -1) desde _j, o noone
function mec_enemigo_delante(_j, _dir)
{
    var _mejor = noone;
    var _dist = infinity;

    with (obj_enemigo)
    {
        if (sign(x - _j.x) == _dir)
        {
            var _d = point_distance(_j.x, _j.y, x, y);
            if (_d < _dist)
            {
                _dist = _d;
                _mejor = id;
            }
        }
    }

    return _mejor;
}


// ==============================
// BARRA DE ULTIMATE GENERAL: una sola para todos los estilos (global.ult_carga, 0..100).
// Cualquier estilo la carga con el daño que hace; la ultimate de Swordmaster (F) la gasta entera y el
// robot del Underdog (F) la va gastando mientras está activo. No carga mientras una ultimate está en curso.
// ==============================
#macro ULT_MAX 100

function mec_ult_carga()
{
    if (!variable_global_exists("ult_carga")) global.ult_carga = 0;
    return global.ult_carga;
}

function mec_ult_set(_v)
{
    global.ult_carga = clamp(_v, 0, ULT_MAX);
}

function mec_ult_en_uso()
{
    var _u = false;
    with (obj_mec_golpe) if (variable_instance_exists(id, "sm_ult_fase") && sm_ult_fase != 0) _u = true;
    with (obj_mecanicas_jugador) if (variable_instance_exists(id, "ub_activo") && ub_activo) _u = true;
    return _u;
}

function mec_ult_cargar(_cantidad)
{
    if (_cantidad <= 0 || mec_ult_en_uso()) return;
    mec_ult_set(mec_ult_carga() + _cantidad);
}

// HUD de la barra en los estilos sin ultimate propia (Shield, Gunner, Base)
function mec_ult_dibujar_general()
{
    var _gw = display_get_gui_width();
    var _ancho = 180;
    var _x2 = _gw - 16;
    var _x1 = _x2 - _ancho;
    var _y = 78;
    var _c = mec_ult_carga();
    var _llena = _c >= ULT_MAX;
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(_x1, _y, _x2, _y + 8, false);
    draw_set_alpha(_llena ? 0.7 + 0.3 * abs(sin(current_time / 120)) : 1);
    draw_set_color(_llena ? c_white : make_color_rgb(180, 140, 255));
    draw_rectangle(_x1, _y, _x1 + _ancho * _c / ULT_MAX, _y + 8, false);
    draw_set_alpha(1);
    draw_set_halign(fa_right);
    draw_set_color(_llena ? c_white : c_ltgray);
    draw_text(_x2, _y + 12, "Ultimate " + string(floor(_c)) + "% (usala en Swordmaster o Underdog)");
    draw_set_halign(fa_left);
    draw_set_color(c_white);
}
