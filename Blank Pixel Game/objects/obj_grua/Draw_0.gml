var _activa = nivel_canal_activo(canal);
var _rx1 = min(x0, x0 + recorrido) - 40;
var _rx2 = max(x0, x0 + recorrido) + 40;

// Riel
draw_set_color(make_color_rgb(40, 44, 58));
draw_rectangle(_rx1, y - 16, _rx2, y - 4, false);
draw_set_color(make_color_rgb(96, 104, 128));
draw_line(_rx1, y - 16, _rx2, y - 16);
draw_set_color(c_black);
draw_rectangle(_rx1, y - 16, _rx2, y - 4, true);
draw_set_color(make_color_rgb(250, 200, 40));
for (var bx = _rx1 + 8; bx < _rx2 - 4; bx += 32) draw_rectangle(bx, y - 12, bx + 3, y - 9, false);

if (!instance_exists(plataforma)) exit;
var _p = plataforma;

// Destino (fantasma) mientras no se ha activado
if (!_activa)
{
    var _gy = y + largo_final;
    draw_set_alpha(0.25 + 0.15 * abs(sin(t * 0.06)));
    draw_set_color(make_color_rgb(250, 200, 40));
    draw_rectangle(x0 + recorrido - 48, _gy, x0 + recorrido + 48, _gy + plat_alto, true);
    draw_line(x0 + recorrido, y, x0 + recorrido, _gy);
    draw_set_alpha(1);
}

// Cable: del carro a un gancho y de ahí a las esquinas de la plataforma
var _hy = _p.bbox_top - 18;
draw_set_color(make_color_rgb(20, 20, 28));
draw_line_width(carro_x, y + 4, carro_x, _hy, 3);
draw_set_color(make_color_rgb(150, 156, 176));
draw_line(carro_x, y + 4, carro_x, _hy);
draw_line_width(carro_x, _hy, _p.bbox_left + 6, _p.bbox_top, 2);
draw_line_width(carro_x, _hy, _p.bbox_right - 6, _p.bbox_top, 2);
draw_set_color(make_color_rgb(250, 200, 40));
draw_circle(carro_x, _hy, 4, false);

// Carro
draw_set_color(make_color_rgb(60, 66, 86));
draw_rectangle(carro_x - 18, y - 20, carro_x + 18, y + 6, false);
draw_set_color(c_black);
draw_rectangle(carro_x - 18, y - 20, carro_x + 18, y + 6, true);
draw_set_color(make_color_rgb(250, 200, 40));
draw_rectangle(carro_x - 16, y - 2, carro_x + 16, y + 3, false);

// Luz de estado: roja esperando, verde activa
var _col = _activa ? make_color_rgb(60, 230, 120) : make_color_rgb(230, 40, 50);
gpu_set_blendmode(bm_add);
draw_set_color(_col);
draw_set_alpha((_activa && progreso < 1) ? 0.6 + 0.4 * abs(sin(t * 0.3)) : 0.7);
draw_circle(carro_x, y - 10, 5, false);
draw_set_alpha(0.2);
draw_circle(carro_x, y - 10, 12, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
