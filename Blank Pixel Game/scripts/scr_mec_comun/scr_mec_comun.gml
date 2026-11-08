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
