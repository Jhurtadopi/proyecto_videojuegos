var _f1 = min(1, fuerza);

// 1) Destello vertical de energía (primeros frames)
if (timer < 7)
{
    var _a = 1 - timer / 7;
    var _ancho = (4 + 6 * _f1) * _a;
    gpu_set_blendmode(bm_add);
    draw_set_color(color);
    draw_set_alpha(0.85 * _a);
    draw_rectangle(x - _ancho, y - (60 + 90 * _f1), x + _ancho, y, false);
    draw_set_alpha(0.5 * _a);
    draw_rectangle(x - _ancho * 3, y - 6, x + _ancho * 3, y, false);
    gpu_set_blendmode(bm_normal);
}

// 2) Polvo (oscuro, a ras de suelo)
var _a_polvo = clamp(1 - timer / 40, 0, 1);
if (_a_polvo > 0)
{
    draw_set_color(make_color_rgb(90, 84, 110));
    draw_set_alpha(0.45 * _a_polvo);
    for (var i = 0; i < array_length(polvo); i++)
    {
        var _p = polvo[i];
        draw_circle(round(_p.x), round(y - _p.r * 0.5), round(_p.r), false);
    }
}

// 3) Grietas: oscuras, con brillo cian que se apaga
var _a_grieta = (timer < duracion - 20) ? 1 : (duracion - timer) / 20;
var _brillo = clamp(1 - timer / 35, 0, 1);
for (var i = 0; i < array_length(grietas); i++)
{
    var _g = grietas[i];
    for (var s = 0; s < array_length(_g) - 1; s++)
    {
        var _ancho_g = max(1, 3 - s);       // más gruesas cerca del impacto
        draw_set_alpha(_a_grieta);
        draw_set_color(color_oscuro);
        draw_line_width(_g[s][0], _g[s][1], _g[s + 1][0], _g[s + 1][1], _ancho_g);

        if (_brillo > 0)
        {
            gpu_set_blendmode(bm_add);
            draw_set_alpha(_brillo * _a_grieta);
            draw_set_color(color);
            draw_line(_g[s][0], _g[s][1], _g[s + 1][0], _g[s + 1][1]);
            gpu_set_blendmode(bm_normal);
        }
    }
}

// 4) Ondas expansivas: dos anillos aplanados (perspectiva lateral)
gpu_set_blendmode(bm_add);
draw_set_color(color);
for (var k = 0; k < 2; k++)
{
    var _t = clamp((timer - k * 5) / 22, 0, 1);
    if (_t <= 0 || _t >= 1) continue;

    var _suave = 1 - power(1 - _t, 3);
    var _r = radio * (0.15 + 0.85 * _suave) * (k == 0 ? 1 : 0.7);
    var _h = (8 + 10 * _f1) * (1 - _t * 0.5);
    draw_set_alpha((1 - _t) * (k == 0 ? 0.9 : 0.6));
    draw_ellipse(x - _r, y - _h, x + _r, y + _h * 0.4, true);
    draw_ellipse(x - _r + 1, y - _h + 1, x + _r - 1, y + _h * 0.4 - 1, true);
}
gpu_set_blendmode(bm_normal);

// 5) Escombros
var _a_esc = clamp(1 - (timer - 25) / 25, 0, 1);
draw_set_alpha(_a_esc);
for (var i = 0; i < array_length(escombros); i++)
{
    var _e = escombros[i];
    draw_set_color(_e.c);
    draw_rectangle(round(_e.x), round(_e.y) - _e.t, round(_e.x) + _e.t - 1, round(_e.y) - 1, false);
}

draw_set_alpha(1);
draw_set_color(c_white);
