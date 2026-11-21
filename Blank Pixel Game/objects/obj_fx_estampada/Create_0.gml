// Efecto visual del impacto de la estampada del Swordmaster.
// Lo crea mec_swordmaster_impacto con { fuerza, radio } (fuerza 0.25 - 1.5 según la altura de la caída).
// Todo es dibujado por código para mantener el estilo pixelado y escalar con la fuerza.
if (!variable_instance_exists(id, "fuerza")) fuerza = 1;
if (!variable_instance_exists(id, "radio")) radio = 100;

depth = -50;            // por encima del suelo y los enemigos, por debajo de las mecánicas
timer = 0;
duracion = 80;          // frames hasta desaparecer (las grietas son lo último en irse)
color = make_color_rgb(0, 230, 255);
color_oscuro = make_color_rgb(18, 16, 28);

var _f1 = min(1, fuerza);

// GRIETAS: polilíneas que salen del punto de impacto hacia los lados, metidas en el suelo
grietas = [];
var _n = 4 + round(4 * fuerza);
for (var i = 0; i < _n; i++)
{
    var _dir = (i mod 2 == 0) ? 1 : -1;
    var _largo = radio * random_range(0.35, 0.85);
    var _segs = irandom_range(3, 6);
    var _px = x + _dir * irandom_range(0, 4);
    var _py = y + 1;
    var _puntos = [[_px, _py]];

    for (var s = 0; s < _segs; s++)
    {
        _px += _dir * (_largo / _segs) * random_range(0.6, 1.3);
        _py = clamp(_py + random_range(-2, 7), y + 1, y + 10 + 22 * _f1);
        array_push(_puntos, [round(_px), round(_py)]);
    }
    array_push(grietas, _puntos);
}

// ESCOMBROS: trozos de suelo que salen disparados
escombros = [];
repeat (10 + round(14 * fuerza))
{
    array_push(escombros, {
        x: x + random_range(-12, 12),
        y: y - 1,
        vx: random_range(-6, 6) * (0.6 + 0.6 * _f1),
        vy: -random_range(3, 10) * (0.6 + 0.5 * _f1),
        t: irandom_range(2, 4),                                  // tamaño en px
        c: choose(color_oscuro, make_color_rgb(70, 64, 90), color)
    });
}

// POLVO: nubes que se expanden a ras de suelo
polvo = [];
repeat (6 + round(4 * fuerza))
{
    var _lado = choose(-1, 1);
    array_push(polvo, { x: x + _lado * random_range(4, 20), vx: _lado * random_range(1.5, 4) * (0.6 + 0.6 * _f1), r: random_range(4, 8) });
}
