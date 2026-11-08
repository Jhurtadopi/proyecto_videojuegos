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
