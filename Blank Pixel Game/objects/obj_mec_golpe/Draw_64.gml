// Ultimate del Swordmaster: oscurecer, cortes, destello y barra de carga
mec_swordmaster_ultimate_dibujar();

// Estilo actual y último golpe, arriba a la derecha
var _x = display_get_gui_width() - 16;
var _swordmaster = (global.estilo == Estilo.SWORDMASTER);

draw_set_halign(fa_right);
draw_set_color(c_white);
draw_text(_x, 16, "Estilo: " + mec_estilo_nombre(global.estilo) + " (1 Swordmaster, 2 Underdog, 3 Shield, 4 Base)");

if (_swordmaster)
{
    draw_text(_x, 36, "W + click en suelo: lanzar | Click en aire: corte | W + click en aire: corte ascendente | S + click en aire: estampar");
}
else if (global.estilo == Estilo.SHIELD)
{
    draw_text(_x, 36, "E: guardia/parry (naranja perfecto, amarillo tardio) | Shift: estampida | Q: lanzar escudo (Q otra vez: volver) | Click: escudazo");
}
else if (global.estilo == Estilo.UNDERDOG)
{
    draw_text(_x, 36, "S: excavar | W + click: taladro arriba | Bajo tierra: Espacio emerger, Shift dash, click pinchazo/arrastre, W + click perforar | Aire: W + click taladro arriba, S + click taladro abajo | F: robot");
}
else if (global.estilo == Estilo.GUNNER)
{
    draw_text(_x, 36, "Click: disparar (apunta con el mouse) | E: cambiar arma | R: recargar");

    // Munición por arma con su icono, arriba a la derecha
    var _arma_i = 0;
    var _recargando = false;
    var _armas = [];
    var _mun = [];

    with (obj_mecanicas_jugador)
    {
        if (variable_instance_exists(id, "gn_armas"))
        {
            _arma_i = gn_arma;
            _recargando = mec_gunner_recargando();
            for (var k = 0; k < array_length(gn_armas); k++)
            {
                array_push(_armas, gn_armas[k]);
                array_push(_mun, gn_municion[k]);
            }
        }
    }

    var _fila = 70;
    for (var k = 0; k < array_length(_armas); k++)
    {
        var _a = _armas[k];
        var _activa = (k == _arma_i);
        var _iy = _fila + k * 24;

        // Icono del arma (munición)
        if (_a.hud_spr != -1)
        {
            var _iw = sprite_get_width(_a.hud_spr);
            draw_sprite_ext(_a.hud_spr, 0, _x - 60, _iy, 1, 1, 0,
                _activa ? c_white : make_color_rgb(120, 120, 120),
                _activa ? 1 : 0.6);
        }

        // Nombre y cantidad
        draw_set_color(_activa ? _a.color : make_color_rgb(140, 140, 140));
        draw_text(_x, _iy - 8, _a.nombre + ":  " + string(_mun[k]) + " / " + string(_a.cargador)
            + ((_activa && _recargando) ? "  (recargando)" : ""));
    }
}

if (golpe_nombre_timer > 0)
{
    draw_set_color(c_yellow);
    draw_text(_x, 56, golpe_nombre);
}

draw_set_halign(fa_left);
draw_set_color(c_white);
