// Fondo y terreno (depth 50: encima del color de fondo de la room, debajo de todo lo demás)
var _cam = view_camera[0];
var _cx = 0, _cy = 0, _vw = room_width, _vh = room_height;
if (_cam != -1)
{
    _cx = camera_get_view_x(_cam);
    _cy = camera_get_view_y(_cam);
    _vw = camera_get_view_width(_cam);
    _vh = camera_get_view_height(_cam);
}

// Cielo
draw_rectangle_colour(_cx, _cy, _cx + _vw, _cy + _vh, cielo_arriba, cielo_arriba, cielo_abajo, cielo_abajo, false);

// Edificios lejanos (parallax 0.25) y cercanos (0.5), con ventanas de neón
var _capas = [[fondo_lejos, 0.25, make_color_rgb(22, 20, 42), neon_b, 0.35, 0.75],
              [fondo_cerca, 0.5, make_color_rgb(30, 26, 52), neon_a, 0.45, 1.0]];
for (var c = 0; c < 2; c++)
{
    var _lista = _capas[c][0];
    var _f = _capas[c][1];
    var _base = _cy + _vh - (room_height - (_cy + _vh)) * _f * 0.3;
    for (var i = 0; i < array_length(_lista); i++)
    {
        var _b = _lista[i];
        var _bx = _cx - _cx * _f + _b.x;
        if (_bx + _b.w < _cx || _bx > _cx + _vw) continue;
        var _top = _base - _b.h * _capas[c][5];
        draw_set_color(_capas[c][2]);
        draw_rectangle(_bx, _top, _bx + _b.w, _base + 40, false);
        draw_set_color(_capas[c][3]);
        draw_set_alpha(_capas[c][4]);
        for (var wy = _top + 10; wy < _base - 6; wy += 18)
            for (var wx = _bx + 6; wx < _bx + _b.w - 8; wx += 14)
                if (((wx - _bx) * 7 + (wy - _top) * 3 + _b.s) mod 11 == 0) draw_rectangle(wx, wy, wx + 5, wy + 3, false);
        draw_set_alpha(1);
    }
}

// Terreno: tiles sobre los obj_solid (superficie arriba si no hay sólido encima)
var _x1 = _cx - 32, _x2 = _cx + _vw + 32, _y1 = _cy - 32, _y2 = _cy + _vh + 32;
with (obj_solid)
{
    if (object_index != obj_solid) continue;
    if (bbox_right < _x1 || bbox_left > _x2 || bbox_bottom < _y1 || bbox_top > _y2) continue;
    var _c0 = max(floor(bbox_left / 32), floor(_x1 / 32));
    var _c1 = min(floor(bbox_right / 32), floor(_x2 / 32));
    var _r0 = max(floor(bbox_top / 32), floor(_y1 / 32));
    var _r1 = min(floor(bbox_bottom / 32), floor(_y2 / 32));
    var _top_fila = floor(bbox_top / 32);
    for (var cc = _c0; cc <= _c1; cc++)
    {
        for (var rr = _r0; rr <= _r1; rr++)
        {
            var _t;
            if (rr == _top_fila && collision_point(cc * 32 + 16, rr * 32 - 16, obj_solid, false, false) == noone) _t = 0;
            else _t = ((cc * 7 + rr * 13) mod 6 == 0) ? 2 : 1;
            draw_sprite(spr_nivel_tile, _t, cc * 32 + 16, rr * 32 + 32);
        }
    }
}
