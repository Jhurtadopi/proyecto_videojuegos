draw_self();
if (activo)
{
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(0, 230, 255));
    draw_set_alpha(0.18 + 0.08 * sin(t * 0.08));
    draw_circle(x - 6, y - 60, 10, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
if (anim > 0) nivel_texto(x, y - 70 - (70 - anim) * 0.4, "CHECKPOINT  +30 vida", make_color_rgb(0, 230, 255), min(1, anim / 20));
draw_set_color(c_white);
