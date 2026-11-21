// ==============================
// ANIMACIÓN DEL JUGADOR
// Elige el sprite de obj_jugador según lo que está haciendo y lo voltea según "mirando".
// Corre en el End Step de obj_mecanicas_jugador, después de todas las mecánicas.
// La colisión no cambia: obj_jugador usa spr_hurtbox (32x64, simétrica) como máscara.
// ==============================

function mec_animacion_fin()
{
    var _j = jugador;
    if (_j == noone || !instance_exists(_j)) return;

    // Hitstop: congelar la animación en el cuadro actual
    if (en_hitstop)
    {
        _j.image_speed = 0;
        return;
    }

    _j.image_xscale = mirando;

    var _suelo = mec_en_suelo(_j);
    var _se_movio = abs(_j.x - x_inicio) > 0.5;
    var _spr;
    var _vel = 1;

    if (mec_parry_golpeando())
    {
        _spr = spr_jugador_ataque;
    }
    else if (mec_dash_activo())
    {
        _spr = spr_jugador_dash;
    }
    else if (!_suelo || mec_gancho_activo())
    {
        _spr = spr_jugador_salto;
        _vel = 0;
    }
    else if (_se_movio)
    {
        _spr = spr_jugador_correr;
    }
    else
    {
        _spr = spr_jugador;   // idle
    }

    if (_j.sprite_index != _spr)
    {
        _j.sprite_index = _spr;
        _j.image_index = 0;
    }

    // Salto: cuadro 0 subiendo, cuadro 1 cayendo
    if (_spr == spr_jugador_salto) _j.image_index = (_j.vsp < 0) ? 0 : 1;

    _j.image_speed = _vel;
}
