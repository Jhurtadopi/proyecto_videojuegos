// ==============================
// JEFE DEMONIO "AZRAEK" y sus diablitos (propios). Funciones que corren en el contexto del jefe
// o del diablito (usan id, x, y, mirando).
// ==============================

function dem_spr(_nombre)
{
    return asset_get_index("spr" + "_enemigo_" + _nombre);
}

function dem_estado(_ia)
{
    ia = _ia;
    ia_t = 0;
    sub = 0;
}

// Mueve en X píxel a píxel sin atravesar sólidos. Devuelve true si chocó.
function dem_mover_x(_dx)
{
    var _s = sign(_dx);
    repeat (floor(abs(_dx)))
    {
        if (place_meeting(x + _s, y, obj_solid)) return true;
        x += _s;
    }
    return false;
}

// Golpe que solo daña al jugador. zona = [adelante desde, adelante hasta, arriba, abajo] desde los pies
// (adelante = hacia donde mira; arriba negativo). Sigue a su dueño mientras dura (_frames).
function dem_golpe(_a0, _a1, _arriba, _abajo, _danio, _kx, _ky, _stagger, _frames)
{
    var _g = instance_create_layer(x, y, layer, obj_golpe_demonio);
    _g.owner = id;
    _g.dueno = id;
    _g.damage = _danio;
    _g.knockback_x = _kx * mirando;
    _g.knockback_y = _ky;
    _g.stagger = _stagger;
    _g.zona = [_a0, _a1, _arriba, _abajo];
    _g.frames = _frames;
    with (_g) dem_golpe_colocar();
    return _g;
}

// Contexto: obj_golpe_demonio
function dem_golpe_colocar()
{
    if (!instance_exists(dueno)) return;
    var _m = dueno.mirando;
    var _xa = dueno.x + zona[0] * _m;
    var _xb = dueno.x + zona[1] * _m;
    x = (_xa + _xb) / 2;
    y = dueno.y + (zona[2] + zona[3]) / 2;
    image_xscale = max(1, abs(_xb - _xa)) / 32;
    image_yscale = max(1, zona[3] - zona[2]) / 32;
}

// Invoca diablitos alrededor del jefe con un destello de portal
function dem_invocar(_n)
{
    for (var i = 0; i < _n; i++)
    {
        var _sx = x + (i - (_n - 1) / 2) * 70 + mirando * 20;
        _sx = clamp(_sx, 48, room_width - 48);
        if (place_meeting(_sx, y - 1, obj_solid)) _sx = x;
        var _d = instance_create_layer(_sx, y - 1, layer, obj_diablito);
        _d.mirando = sign(x - _sx) == 0 ? 1 : -sign(x - _sx);
        array_push(portales, { x: _sx, y: y - 20, t: 30 });
    }
    with (obj_camara) aplicar_temblor(4, 14);
}

// Elige sprite y cuadro del jefe según su estado de IA
function dem_animar(_suelo)
{
    var _s = -1;
    var _i = 0;
    var _rap = (fase == 2) ? 1.4 : 1;
    var _se_mueve = abs(x - prev_x) > 0.5;
    switch (ia)
    {
        case "intro":
        case "invocar":
        case "transicion":
            _s = spr.invocar; _i = (t div 8) mod 2; break;
        case "espera":
            if (!_suelo) { _s = spr.aire; _i = 0; }
            else if (_se_mueve) { _s = spr.correr; _i = (t div 4) mod 4; }
            else { _s = spr.idle; _i = (t div 14) mod 2; }
            break;
        case "dash":
            if (ia_t < round(14 / _rap)) { _s = spr.tajo; _i = 0; }
            else { _s = spr.correr; _i = (t div 2) mod 4; }
            break;
        case "combo":
            var _L = round(12 / _rap);
            var _paso = ia_t div _L;
            var _f = ia_t mod _L;
            if (_paso >= 2) { _s = spr.lanzador; _i = (_f < 3) ? 0 : 1; }
            else { _s = spr.tajo; _i = min(2, _f div max(1, _L div 3)); }
            break;
        case "aire":
            if (sub > 0) { _s = spr.aire; _i = (sub > 6) ? 0 : 1; }
            else { _s = spr.lanzador; _i = 1; }
            break;
        case "picada":
            _s = spr.picada; _i = (ia_t < 6) ? 0 : 1; break;
        case "escape":
            _s = spr.esquiva; _i = 0; break;
        case "bolas":
            _s = spr.invocar; _i = 1; break;
        default:
            _s = spr.aturdido; _i = 0; break;
    }
    if (_s == -1) { _s = spr.idle; _i = (t div 14) mod 2; }
    if (_s == -1) { _s = spr_base; _i = 0; }
    sprite_index = _s;
    image_index = min(_i, sprite_get_number(_s) - 1);
    image_speed = 0;
}
