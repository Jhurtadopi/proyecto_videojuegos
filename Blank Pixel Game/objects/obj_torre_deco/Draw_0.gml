var _top = y - alto;
var _w = 22;
var _osc = make_color_rgb(28, 32, 48);
var _med = make_color_rgb(58, 64, 88);
// Patas
draw_set_color(_osc);
draw_rectangle(x - _w, _top, x - _w + 5, y, false);
draw_rectangle(x + _w - 5, _top, x + _w, y, false);
draw_set_color(_med);
draw_line(x - _w + 5, _top, x - _w + 5, y);
draw_line(x + _w - 5, _top, x + _w - 5, y);
// Celosía
for (var _yy = _top; _yy < y; _yy += 32)
{
    var _y2 = min(y, _yy + 32);
    draw_set_color(_osc);
    draw_line_width(x - _w + 3, _yy, x + _w - 3, _y2, 3);
    draw_line_width(x + _w - 3, _yy, x - _w + 3, _y2, 3);
    draw_set_color(_med);
    draw_line_width(x - _w, _yy, x + _w, _yy, 2);
}
// Base
draw_set_color(_osc);
draw_rectangle(x - _w - 8, y - 10, x + _w + 8, y, false);
draw_set_color(_med);
draw_line(x - _w - 8, y - 10, x + _w + 8, y - 10);
// Luz de aviso
gpu_set_blendmode(bm_add);
draw_set_color(make_color_rgb(255, 40, 40));
draw_set_alpha(0.35 + 0.35 * abs(sin(t * 0.05)));
draw_circle(x - _w + 2, _top + 6, 4, false);
draw_circle(x + _w - 2, _top + 6, 4, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
