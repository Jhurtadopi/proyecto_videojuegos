// ==============================
// GANCHO (balanceo con cuerda de largo ajustable, estilo Wrecking Ball de Overwatch)
// Se apunta con el mouse. Mantener click derecho lo lanza hacia el cursor: si
// encuentra una superficie sólida en el camino, se engancha y da un impulso
// inicial hacia ese punto. Mientras cuelga, W retrae la cuerda (subís ganando
// velocidad, conservando el momento angular) y S te devuelve hacia el ancla
// cuando estás arriba de ella; así el jugador elige un gancho más lateral
// (cuerda larga, cubre distancia) o uno para ganar altura (cuerda corta).
// A/D llevan el impulso a lo largo de la cuerda hacia ese lado conservando la
// velocidad. Al subir, la gravedad se reduce poco a poco para que el impulso
// se sostenga y se pueda pasar por encima del ancla. Shift durante el gancho
// no hace dash: acelera el balanceo. Soltar el click derecho (en cualquier
// momento) cancela el gancho y conserva la velocidad en X y en Y.
// ==============================

enum GanchoEstado
{
    INACTIVO,
    LANZANDO,
    BALANCEANDO
}

function mec_gancho_crear()
{
    gancho_alcance_max = 420;          // px
    gancho_velocidad_disparo = 48;     // velocidad de la punta mientras vuela hacia el punto
    gancho_impulso_inicial = 14;        // empuje hacia el ancla en el instante de enganchar
    gancho_boost_mult = 1.5;          // multiplicador de velocidad al usar Shift en pleno gancho
    gancho_giro_max = 12;               // grados/frame que A/D pueden redirigir el impulso
    gancho_largo_min = 24;             // piso del largo de la cuerda al enganchar (evita radio 0)
    gancho_largo_piso = 8;             // piso absoluto de la cuerda (evita radio ~0)
    gancho_retraer_vel = 4;            // px/frame que acorta la cuerda al mantener W
    gancho_retraer_tope = 30;          // hasta qué velocidad puede acelerar W al retraer
    gancho_tiron_s = 1;                // px/frame² hacia el ancla al mantener S estando arriba de ella
    gancho_gravedad_subida = 0.8;      // fracción de la gravedad que queda al subir (1 = sin ayuda)
    gancho_gravedad_rampa = 20;        // frames subiendo hasta llegar a esa fracción
    gancho_empuje_lateral = 0.6;       // aceleración con A/D (actúa sobre todo abajo del arco)
    gancho_velocidad_lateral = 22;     // hasta qué velocidad pueden acelerar A/D
    gancho_inercia_friccion = 0.985;   // pérdida por frame de la velocidad en X tras soltar
    gancho_inercia_freno = 0.9;        // igual, pero pulsando la dirección contraria
    gancho_velocidad_max = 70;         // tope general de velocidad del balanceo
    gancho_cooldown_max = 16;          // tras soltar el gancho
    gancho_cooldown_fallo = 10;        // tras un disparo que no encontró nada

    gancho_estado = GanchoEstado.INACTIVO;
    gancho_cooldown = 0;

    gancho_punta_x = 0;
    gancho_punta_y = 0;
    gancho_ancla_x = 0;                // punto fijo del que cuelga la cuerda
    gancho_ancla_y = 0;
    gancho_dir = 0;

    gancho_largo = 0;                  // largo actual de la cuerda (W la acorta)
    gancho_vx = 0;                     // velocidad del balanceo (propia, no es la del jugador)
    gancho_vy = 0;
    gancho_subida_frames = 0;          // frames seguidos subiendo durante el balanceo
    gancho_inercia_x = 0;              // velocidad en X que se conserva tras soltar

    gancho_hay_objetivo = false;       // hay algo enganchable bajo el cursor (para la mira)
}

function mec_gancho_activo()
{
    return gancho_estado != GanchoEstado.INACTIVO;
}

// Punto desde donde sale el gancho y del que cuelga la cuerda (altura del pecho de _j)
function mec_gancho_origen(_j)
{
    return [_j.x, _j.y - _j.sprite_height * 0.6];
}

// Busca el primer punto sólido en línea recta desde (_x0, _y0) hacia _dir, hasta _max_dist.
// Devuelve { encontrado, x, y }.
function mec_gancho_buscar_punto(_x0, _y0, _dir, _max_dist)
{
    var _paso = 4;
    var _dist = 0;
    var _ax = _x0;
    var _ay = _y0;

    while (_dist < _max_dist)
    {
        var _bx = _ax;
        var _by = _ay;

        _dist += _paso;
        _ax = _x0 + lengthdir_x(_dist, _dir);
        _ay = _y0 + lengthdir_y(_dist, _dir);

        if (collision_point(_ax, _ay, obj_solid, false, true) != noone)
        {
            // Afina el punto de impacto retrocediendo en pasos de 1px
            var _fx = _bx;
            var _fy = _by;

            for (var _d = 1; _d <= _paso; _d++)
            {
                var _tx = _bx + lengthdir_x(_d, _dir);
                var _ty = _by + lengthdir_y(_d, _dir);
                if (collision_point(_tx, _ty, obj_solid, false, true) != noone) break;
                _fx = _tx;
                _fy = _ty;
            }

            return { encontrado: true, x: _fx, y: _fy };
        }
    }

    return { encontrado: false, x: _ax, y: _ay };
}

// Cancela el gancho: si ya estaba balanceándose, conserva su velocidad.
// obj_jugador reescribe hsp cada frame según A/D, así que la velocidad en X se
// guarda aparte y se aplica en mec_gancho_inercia.
function mec_gancho_soltar()
{
    if (gancho_estado == GanchoEstado.BALANCEANDO)
    {
        gancho_inercia_x = gancho_vx;
        jugador.vsp = gancho_vy;
    }

    gancho_estado = GanchoEstado.INACTIVO;
    gancho_cooldown = gancho_cooldown_max;
}

// End Step: tras soltar, la velocidad en X manda sobre el caminar hasta aterrizar,
// chocar o bajar a la velocidad normal (mismo patrón que el dash y el salto en pared)
function mec_gancho_inercia()
{
    if (gancho_inercia_x == 0) return;

    var _j = jugador;

    if (mec_dash_activo() || walljump_bloqueo > 0 || mec_en_suelo(_j))
    {
        gancho_inercia_x = 0;
        return;
    }

    var _input = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    var _frenando = (_input != 0 && _input != sign(gancho_inercia_x));
    gancho_inercia_x *= _frenando ? gancho_inercia_freno : gancho_inercia_friccion;

    if (abs(gancho_inercia_x) <= _j.velocidad_normal)
    {
        gancho_inercia_x = 0;
        return;
    }

    var _objetivo = x_inicio + gancho_inercia_x;
    mec_mover_hasta_x(_j, _objetivo);

    if (abs(_j.x - _objetivo) >= 1) gancho_inercia_x = 0;      // chocó con una pared
}

// Begin Step
function mec_gancho_inicio()
{
    var _j = jugador;

    gancho_cooldown = max(0, gancho_cooldown - 1);
    gancho_hay_objetivo = false;

    switch (gancho_estado)
    {
        case GanchoEstado.INACTIVO:

            var _origen = mec_gancho_origen(_j);
            var _dir_mira = point_direction(_origen[0], _origen[1], mouse_x, mouse_y);
            var _vista = mec_gancho_buscar_punto(_origen[0], _origen[1], _dir_mira, gancho_alcance_max);
            gancho_hay_objetivo = _vista.encontrado;

            if (mouse_check_button_pressed(mb_right) && gancho_cooldown == 0
                && !mec_dash_activo() && !mec_parry_golpeando())
            {
                gancho_dir = _dir_mira;

                if (_vista.encontrado)
                {
                    gancho_punta_x = _origen[0];
                    gancho_punta_y = _origen[1];
                    gancho_ancla_x = _vista.x;
                    gancho_ancla_y = _vista.y;
                    gancho_estado = GanchoEstado.LANZANDO;
                    mirando = (gancho_ancla_x >= _j.x) ? 1 : -1;
                }
                else
                {
                    gancho_cooldown = gancho_cooldown_fallo;
                }
            }

        break;


        case GanchoEstado.LANZANDO:

            // Mantener apretado el click; si se suelta antes de enganchar, se cancela
            if (!mouse_check_button(mb_right))
            {
                mec_gancho_soltar();
                break;
            }

            var _avance_punta = min(gancho_velocidad_disparo,
                point_distance(gancho_punta_x, gancho_punta_y, gancho_ancla_x, gancho_ancla_y));

            gancho_punta_x += lengthdir_x(_avance_punta, gancho_dir);
            gancho_punta_y += lengthdir_y(_avance_punta, gancho_dir);

            if (point_distance(gancho_punta_x, gancho_punta_y, gancho_ancla_x, gancho_ancla_y) < 1)
            {
                // Se engancha: el largo de la cuerda queda fijo a la distancia actual
                // y recibe un empuje inicial hacia el ancla (conservando la velocidad previa).
                var _origen2 = mec_gancho_origen(_j);
                var _dx = _origen2[0] - gancho_ancla_x;
                var _dy = _origen2[1] - gancho_ancla_y;
                var _dir_a_ancla = point_direction(_origen2[0], _origen2[1], gancho_ancla_x, gancho_ancla_y);

                var _vx_previa = (gancho_inercia_x != 0) ? gancho_inercia_x : _j.hsp;

                gancho_largo = max(gancho_largo_min, point_distance(0, 0, _dx, _dy));
                gancho_vx = _vx_previa + lengthdir_x(gancho_impulso_inicial, _dir_a_ancla);
                gancho_vy = _j.vsp + lengthdir_y(gancho_impulso_inicial, _dir_a_ancla);
                gancho_subida_frames = 0;
                gancho_inercia_x = 0;

                gancho_estado = GanchoEstado.BALANCEANDO;
            }

        break;


        case GanchoEstado.BALANCEANDO:

            // Mantener apretado el click; al soltarlo se cancela con la velocidad actual
            if (!mouse_check_button(mb_right))
            {
                mec_gancho_soltar();
                break;
            }

            // Shift en pleno gancho no hace dash (ver scr_mec_dash): acelera el balanceo
            if (keyboard_check_pressed(vk_shift))
            {
                gancho_vx *= gancho_boost_mult;
                gancho_vy *= gancho_boost_mult;
            }

            // Gravedad completa al bajar; al subir se va reduciendo para que el impulso se sostenga
            gancho_subida_frames = (gancho_vy < 0) ? gancho_subida_frames + 1 : 0;
            var _avance_subida = min(1, gancho_subida_frames / gancho_gravedad_rampa);
            gancho_vy += _j.gravedad * lerp(1, gancho_gravedad_subida, _avance_subida);

            var _origen_actual = mec_gancho_origen(_j);

            // A/D llevan el impulso a lo largo de la cuerda hacia ese lado conservando la velocidad.
            // Sigue la tangente (no la horizontal) para no gastar la subida, y arriba del ancla
            // no actúa: ahí la tangente hacia ese lado apunta hacia abajo y frenaría el ascenso.
            var _input_dir = keyboard_check(ord("D")) - keyboard_check(ord("A"));
            if (_input_dir != 0 && _origen_actual[1] > gancho_ancla_y)
            {
                var _tangente = point_direction(gancho_ancla_x, gancho_ancla_y, _origen_actual[0], _origen_actual[1]) + 90;
                if (sign(lengthdir_x(1, _tangente)) != _input_dir) _tangente += 180;

                var _velocidad = point_distance(0, 0, gancho_vx, gancho_vy);
                var _dir_actual = point_direction(0, 0, gancho_vx, gancho_vy);
                var _giro = clamp(angle_difference(_tangente, _dir_actual), -gancho_giro_max, gancho_giro_max);
                var _dir_final = _dir_actual + _giro;

                if (_velocidad < gancho_velocidad_lateral)
                {
                    var _empuje = gancho_empuje_lateral * abs(lengthdir_x(1, _tangente));
                    _velocidad = min(gancho_velocidad_lateral, _velocidad + _empuje);
                }

                gancho_vx = lengthdir_x(_velocidad, _dir_final);
                gancho_vy = lengthdir_y(_velocidad, _dir_final);
            }

            var _dist_actual = point_distance(gancho_ancla_x, gancho_ancla_y, _origen_actual[0], _origen_actual[1]);

            if (keyboard_check(ord("W")))
            {
                // Si la cuerda estaba floja se parte de la distancia real, así W responde al instante
                var _largo_base = min(gancho_largo, _dist_actual);
                var _nuevo_largo = max(gancho_largo_piso, _largo_base - gancho_retraer_vel);

                if (_largo_base > 1)
                {
                    // Conserva el momento angular (r * v_tangencial = cte): retraer acelera el balanceo,
                    // pero solo hasta gancho_retraer_tope; la velocidad que ya venga por encima se respeta.
                    var _dir_radial3 = point_direction(gancho_ancla_x, gancho_ancla_y, _origen_actual[0], _origen_actual[1]);
                    var _tan_x3 = lengthdir_x(1, _dir_radial3 + 90);
                    var _tan_y3 = lengthdir_y(1, _dir_radial3 + 90);
                    var _rad_x3 = lengthdir_x(1, _dir_radial3);
                    var _rad_y3 = lengthdir_y(1, _dir_radial3);

                    var _vel_tan3 = dot_product(gancho_vx, gancho_vy, _tan_x3, _tan_y3);
                    if (abs(_vel_tan3) < gancho_retraer_tope)
                    {
                        _vel_tan3 = sign(_vel_tan3) * min(gancho_retraer_tope, abs(_vel_tan3) * _largo_base / _nuevo_largo);
                    }
                    var _vel_rad3 = dot_product(gancho_vx, gancho_vy, _rad_x3, _rad_y3);

                    gancho_vx = _tan_x3 * _vel_tan3 + _rad_x3 * _vel_rad3;
                    gancho_vy = _tan_y3 * _vel_tan3 + _rad_y3 * _vel_rad3;
                }

                gancho_largo = _nuevo_largo;
            }
            else if (keyboard_check(ord("S")) && _origen_actual[1] < gancho_ancla_y)
            {
                // Arriba del ancla, S te tira de vuelta hacia ella
                var _hacia_ancla = point_direction(_origen_actual[0], _origen_actual[1], gancho_ancla_x, gancho_ancla_y);
                gancho_vx += lengthdir_x(gancho_tiron_s, _hacia_ancla);
                gancho_vy += lengthdir_y(gancho_tiron_s, _hacia_ancla);
            }

        break;
    }
}

// End Step: después del Step de obj_jugador, así la cuerda manda sobre su movimiento normal
function mec_gancho_fin()
{
    if (gancho_estado != GanchoEstado.BALANCEANDO)
    {
        mec_gancho_inercia();
        return;
    }

    var _j = jugador;

    // obj_jugador ya aplicó este frame su caminar y su gravedad: se descartan
    // para que no se sumen al balanceo (la gravedad arrastraba hasta 12 px/frame).
    _j.x = x_inicio;
    _j.y = y_inicio;
    _j.hsp = 0;
    _j.vsp = 0;

    var _origen = mec_gancho_origen(_j);

    var _nx = _origen[0] + gancho_vx;
    var _ny = _origen[1] + gancho_vy;

    if (point_distance(gancho_ancla_x, gancho_ancla_y, _nx, _ny) > gancho_largo)
    {
        // La cuerda solo frena lo que tira hacia afuera. La velocidad tangencial se mide
        // antes de mover y se reaplica sobre la tangente nueva, para no perderla cada frame.
        var _tan_antes = point_direction(gancho_ancla_x, gancho_ancla_y, _origen[0], _origen[1]) + 90;
        var _vel_tangencial = dot_product(gancho_vx, gancho_vy, lengthdir_x(1, _tan_antes), lengthdir_y(1, _tan_antes));

        var _dir_radial = point_direction(gancho_ancla_x, gancho_ancla_y, _nx, _ny);
        _nx = gancho_ancla_x + lengthdir_x(gancho_largo, _dir_radial);
        _ny = gancho_ancla_y + lengthdir_y(gancho_largo, _dir_radial);

        gancho_vx = lengthdir_x(_vel_tangencial, _dir_radial + 90);
        gancho_vy = lengthdir_y(_vel_tangencial, _dir_radial + 90);
    }

    // Tope general: que retraer la cuerda (W) no dispare la velocidad sin control
    var _rapidez = point_distance(0, 0, gancho_vx, gancho_vy);
    if (_rapidez > gancho_velocidad_max)
    {
        var _dir_vel = point_direction(0, 0, gancho_vx, gancho_vy);
        gancho_vx = lengthdir_x(gancho_velocidad_max, _dir_vel);
        gancho_vy = lengthdir_y(gancho_velocidad_max, _dir_vel);
    }

    // Al chocar solo se pierde la velocidad de ese eje: el jugador se desliza por la superficie
    var _choque = mec_mover_con_choque(_j, _nx - _origen[0], _ny - _origen[1]);
    if (_choque[0]) gancho_vx = 0;
    if (_choque[1]) gancho_vy = 0;
}
