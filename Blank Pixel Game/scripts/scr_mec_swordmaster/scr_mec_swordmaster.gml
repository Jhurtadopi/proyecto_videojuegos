// ==============================
// ESTILO SWORDMASTER
// Espada a corta distancia con alto control en el aire: lanza enemigos, los mantiene
// arriba con cortes aéreos y los estampa contra el suelo.
// Las funciones corren en el contexto de obj_mec_golpe. El dash de este estilo es el
// dash base. Cada corte usa el click del golpe, así que también hace parry.
// ==============================

function mec_swordmaster_crear()
{
    sm_lanzar_vel = -13;    // velocidad del lanzamiento; enemigo y jugador usan la misma para subir juntos
    sm_aire_vel = -2;       // velocidad vertical al conectar un corte aéreo (enemigo y jugador)
    sm_estampar_vel = 16;   // velocidad hacia abajo del enemigo estampado

    // ESTAMPADA DEL JUGADOR: suspensión breve y caída en picada que rompe el suelo.
    // La caída se aplica en el End Step (mec_swordmaster_picado_fin), así supera el tope
    // de 12 px/frame que obj_jugador pone a vsp.
    sm_picado_espera = 6;           // frames suspendido en el aire antes de caer (anticipación)
    sm_picado_vel_inicial = 16;     // px/frame al empezar a caer
    sm_picado_acel = 2.5;           // aceleración por frame
    sm_picado_vel_max = 36;         // px/frame máximos

    sm_picado = false;              // el jugador está en la estampada
    sm_picado_fase = 0;             // 1 = suspendido, 2 = cayendo
    sm_picado_timer = 0;
    sm_picado_vel = 0;
    sm_picado_y0 = 0;               // altura donde empezó (la fuerza del impacto depende de la caída)

    // ONDA EXPANSIVA al tocar el suelo (escala con la altura de la caída)
    sm_onda_altura_ref = 320;       // px de caída para la fuerza completa (1.0); tope 1.5
    sm_onda_radio_min = 56;
    sm_onda_radio_max = 150;
    sm_onda_danio_min = 6;
    sm_onda_danio_max = 18;
    sm_onda_empuje_x = 5;
    sm_onda_empuje_y = -7;          // levanta un poco a los enemigos cercanos
    sm_onda_stagger = 40;

    // ULTIMATE "JUICIO DIMENSIONAL" (F). Por ahora se carga con el daño hecho; cuando existan los
    // rangos de estilo, la condición será estar en rango S (cambiar mec_swordmaster_ultimate_lista).
    sm_ult_carga = 0;
    sm_ult_max = 100;               // daño necesario para cargarlo
    sm_ult_fase = 0;                // 0 inactivo, 1 cortes (mundo congelado), 2 detonación
    sm_ult_timer = 0;
    sm_ult_preparacion = 40;        // frames de cortes antes de detonar
    sm_ult_radio = 420;             // px alrededor del jugador
    sm_ult_danio = 30;
    sm_ult_stagger = 90;
    sm_ult_empuje_y = -8;
    sm_ult_objetivos = [];
    sm_ult_cortes = [];             // [{x, y, ang, largo, t}] líneas que se dibujan en pantalla
    sm_ult_flash = 0;

    // kx se multiplica por la dirección en que mira el jugador.
    // jugador_vsp se aplica al jugador solo si el golpe conecta (undefined = no lo mueve).
    // stagger: frames que el enemigo queda aturdido (no ataca).
    // zona: [adelante_desde, adelante_hasta, arriba, abajo] en px desde los pies del jugador.
    //   "adelante" se mide hacia donde mira; arriba es negativo (el jugador mide 64 px).
    sm_corte1 = { nombre: "Corte 1", danio: 8, kx: 2, ky: 0, stagger: 18, hitstop: 4, jugador_vsp: undefined,
                  zona: [-8, 44, -64, 0] };
    sm_corte2 = { nombre: "Corte 2", danio: 8, kx: 2, ky: 0, stagger: 18, hitstop: 4, jugador_vsp: undefined,
                  zona: [-8, 46, -64, 0] };
    sm_remate = { nombre: "Remate", danio: 14, kx: 9, ky: -3, stagger: 30, hitstop: 8, jugador_vsp: undefined,
                  zona: [-8, 56, -70, 0] };
    sm_lanzador = { nombre: "Lanzador", danio: 8, kx: 0, ky: sm_lanzar_vel, stagger: 40, hitstop: 7, jugador_vsp: sm_lanzar_vel,
                    zona: [-6, 40, -104, 0] };      // alto: alcanza enemigos encima
    // kx_input: si al golpear se mantiene A o D, el enemigo sale hacia ese lado con esta velocidad
    // (el jugador camina a 6 en el aire, así que puede seguirlo y continuar el combo)
    sm_aereo = { nombre: "Corte aereo", danio: 6, kx: 1, kx_input: 5, ky: sm_aire_vel, stagger: 25, hitstop: 4, jugador_vsp: sm_aire_vel,
                 zona: [-10, 48, -80, 12] };
    // W + click en el aire: corte hacia arriba (lanza al enemigo de encima y eleva un poco al jugador)
    sm_corte_arriba = { nombre: "Corte ascendente", danio: 7, kx: 0, ky: -10, stagger: 30, hitstop: 5, jugador_vsp: -6,
                        zona: [-24, 30, -130, -20] };
    sm_estampada = { nombre: "Estampada", danio: 12, kx: 0, ky: sm_estampar_vel, stagger: 45, hitstop: 8, jugador_vsp: undefined,
                     zona: [-18, 40, -40, 56] };    // hacia abajo: alcanza enemigos debajo

    // COMBO EN EL SUELO: corte 1 -> corte 2 -> remate
    sm_combo = [sm_corte1, sm_corte2, sm_remate];
    sm_combo_paso = 0;          // próximo paso del combo
    sm_combo_timer = 0;         // > 0: el siguiente click sigue el combo
    sm_combo_ventana = 14;      // frames tras terminar un corte para encadenar el siguiente
}

// Zona del golpe en coordenadas del mundo: [x1, y1, x2, y2]. undefined si el golpe no define zona.
function mec_golpe_zona(_j, _mirando, _g)
{
    if (!is_struct(_g) || !variable_struct_exists(_g, "zona")) return undefined;

    var _z = _g.zona;
    var _xa = _j.x + _z[0] * _mirando;
    var _xb = _j.x + _z[1] * _mirando;
    return [min(_xa, _xb), _j.y + _z[2], max(_xa, _xb), _j.y + _z[3]];
}

// Elige el corte según el input en el momento de golpear
function mec_swordmaster_elegir_golpe(_j)
{
    if (mec_en_suelo(_j))
    {
        if (keyboard_check(ord("W")))
        {
            sm_combo_paso = 0;
            sm_combo_timer = 0;
            return sm_lanzador;
        }

        // Combo: si el click llega dentro de la ventana, sigue; si no, empieza de nuevo
        if (sm_combo_timer <= 0) sm_combo_paso = 0;

        var _g = sm_combo[sm_combo_paso];
        var _duracion = 18;
        with (obj_mecanicas_jugador) _duracion = parry_duracion;

        if (sm_combo_paso < array_length(sm_combo) - 1)
        {
            sm_combo_paso++;
            sm_combo_timer = _duracion + sm_combo_ventana;
        }
        else
        {
            sm_combo_paso = 0;      // tras el remate, el combo vuelve a empezar
            sm_combo_timer = 0;
        }

        return _g;
    }

    if (keyboard_check(ord("S")))
    {
        if (!sm_picado)         // el jugador cae, conecte o no
        {
            sm_picado = true;
            sm_picado_fase = 1;
            sm_picado_timer = sm_picado_espera;
            sm_picado_vel = sm_picado_vel_inicial;
            sm_picado_y0 = _j.y;
        }
        return sm_estampada;
    }

    if (keyboard_check(ord("W"))) return sm_corte_arriba;

    return sm_aereo;
}

// Mantiene la caída de la estampada hasta aterrizar o usar el dash o el gancho
function mec_swordmaster_paso(_j)
{
    sm_combo_timer = max(0, sm_combo_timer - 1);
    if (instance_exists(_j) && !mec_en_suelo(_j)) sm_combo_timer = 0;   // saltar corta el combo

    if (!sm_picado) return;

    var _cancelar = !instance_exists(_j);

    with (obj_mecanicas_jugador)
    {
        if (mec_dash_activo() || mec_gancho_activo()) _cancelar = true;
    }

    if (_cancelar)
    {
        sm_picado = false;
        sm_picado_fase = 0;
        return;
    }

    // obj_jugador suma gravedad: suspendido se compensa para quedar quieto
    _j.vsp = (sm_picado_fase == 1) ? -_j.gravedad : 12;
}

// End Step (llamado desde obj_mecanicas_jugador): mueve al jugador en la estampada
function mec_swordmaster_picado_fin(_j, _y_inicio)
{
    if (!sm_picado || !instance_exists(_j)) return;

    if (sm_picado_fase == 1)
    {
        // Suspendido: se queda arriba (sube 1 px) mientras prepara el golpe
        mec_mover_con_choque(_j, 0, (_y_inicio - 1) - _j.y);
        _j.vsp = 0;

        sm_picado_timer--;
        if (sm_picado_timer <= 0) sm_picado_fase = 2;
        return;
    }

    // Cayendo: acelera y supera el tope de obj_jugador
    sm_picado_vel = min(sm_picado_vel_max, sm_picado_vel + sm_picado_acel);
    var _objetivo = _y_inicio + sm_picado_vel;
    if (_objetivo > _j.y) mec_mover_con_choque(_j, 0, _objetivo - _j.y);
    _j.vsp = 12;

    if (mec_en_suelo(_j)) mec_swordmaster_impacto(_j);
}

// Toca el suelo: onda expansiva, hitstop, temblor y efecto visual
function mec_swordmaster_impacto(_j)
{
    sm_picado = false;
    sm_picado_fase = 0;

    var _caida = max(0, _j.y - sm_picado_y0);
    var _f = clamp(_caida / sm_onda_altura_ref, 0.25, 1.5);
    var _f1 = min(1, _f);
    var _radio = lerp(sm_onda_radio_min, sm_onda_radio_max, _f1);
    var _danio = round(lerp(sm_onda_danio_min, sm_onda_danio_max, _f1));
    var _vx = sm_onda_empuje_x;
    var _vy = sm_onda_empuje_y * (0.6 + 0.4 * _f1);
    var _stg = sm_onda_stagger;
    var _jx = _j.x;
    var _jy = _j.y;

    with (obj_enemigo)
    {
        // El enemigo que viene estampado ya recibe su propio golpe contra el suelo
        if (!estampado)
        {
            var _dx = x - _jx;
            if (abs(_dx) <= _radio && abs(y - _jy) <= 48)
            {
                var _cerca = 1 - abs(_dx) / _radio;
                var _lado = (_dx == 0) ? 1 : sign(_dx);
                recibir_impacto(_danio, _lado * _vx * (0.5 + _cerca), lanzable ? _vy : 0, _stg);
                with (obj_mec_golpe) mec_swordmaster_ultimate_cargar(_danio);
            }
        }
    }

    var _hs = round(4 + 4 * _f1);
    var _tb = 3 + 7 * _f1;
    with (obj_controladores) aplicar_hitstop(_hs);
    with (obj_camara) aplicar_temblor(_tb, 18);

    instance_create_layer(_jx, _jy, "Instances", obj_fx_estampada, { fuerza: _f, radio: _radio });

    golpe_nombre = "IMPACTO x" + string_format(_f, 1, 1);
    golpe_nombre_timer = 40;
}


// ==============================
// ULTIMATE: JUICIO DIMENSIONAL
// Corre en el Step de obj_mec_golpe ANTES de la salida por hitstop (el ultimate congela el mundo).
// ==============================

function mec_swordmaster_ultimate_lista()
{
    return global.estilo == Estilo.SWORDMASTER && sm_ult_carga >= sm_ult_max;
}

function mec_swordmaster_ultimate_cargar(_cantidad)
{
    if (sm_ult_fase == 0 && global.estilo == Estilo.SWORDMASTER)
        sm_ult_carga = min(sm_ult_max, sm_ult_carga + _cantidad);
}

function mec_swordmaster_ultimate_paso()
{
    sm_ult_flash = max(0, sm_ult_flash - 1);
    var _j = instance_exists(obj_jugador) ? instance_find(obj_jugador, 0) : noone;

    switch (sm_ult_fase)
    {
        case 0:
            if (!keyboard_check_pressed(ord("F")) || !mec_swordmaster_ultimate_lista() || _j == noone) break;

            sm_ult_objetivos = [];
            var _lista = sm_ult_objetivos;
            var _radio = sm_ult_radio;
            with (obj_enemigo)
            {
                if (point_distance(x, y, _j.x, _j.y) <= _radio) array_push(_lista, id);
            }
            sm_ult_objetivos = _lista;

            sm_ult_carga = 0;
            sm_ult_fase = 1;
            sm_ult_timer = sm_ult_preparacion;
            sm_ult_cortes = [];

            var _congelar = sm_ult_preparacion + 2;
            var _prep = sm_ult_preparacion;
            with (obj_controladores) aplicar_hitstop(_congelar);
            with (obj_camara) aplicar_temblor(2, _prep);

            golpe_nombre = "JUICIO DIMENSIONAL";
            golpe_nombre_timer = 90;
        break;

        case 1:
            sm_ult_timer--;

            // Un corte nuevo cada 2 frames sobre un objetivo al azar (o alrededor del jugador)
            if (sm_ult_timer mod 2 == 0)
            {
                var _cx, _cy;
                var _n = array_length(sm_ult_objetivos);
                var _obj = (_n > 0) ? sm_ult_objetivos[irandom(_n - 1)] : noone;
                if (instance_exists(_obj))
                {
                    _cx = (_obj.bbox_left + _obj.bbox_right) / 2 + random_range(-12, 12);
                    _cy = (_obj.bbox_top + _obj.bbox_bottom) / 2 + random_range(-12, 12);
                }
                else if (_j != noone)
                {
                    _cx = _j.x + random_range(-sm_ult_radio, sm_ult_radio) * 0.5;
                    _cy = _j.y - 32 + random_range(-120, 60);
                }
                else { _cx = room_width / 2; _cy = room_height / 2; }

                array_push(sm_ult_cortes, { x: _cx, y: _cy, ang: random(180), largo: random_range(50, 110), t: 0 });
            }
            for (var i = 0; i < array_length(sm_ult_cortes); i++) sm_ult_cortes[i].t++;

            if (sm_ult_timer <= 0)
            {
                // Detonación: todos los objetivos reciben el golpe a la vez
                global.hitstop_timer = 0;
                var _d = sm_ult_danio;
                var _ky = sm_ult_empuje_y;
                var _st = sm_ult_stagger;
                for (var k = 0; k < array_length(sm_ult_objetivos); k++)
                {
                    var _e = sm_ult_objetivos[k];
                    if (instance_exists(_e))
                    {
                        var _kx = random_range(-3, 3);
                        with (_e) recibir_impacto(_d, _kx, _ky, _st);
                    }
                }
                with (obj_controladores) aplicar_hitstop(10);
                with (obj_camara) aplicar_temblor(12, 26);
                sm_ult_flash = 12;
                sm_ult_fase = 2;
                sm_ult_timer = 30;
            }
        break;

        case 2:
            sm_ult_timer--;
            for (var i = 0; i < array_length(sm_ult_cortes); i++) sm_ult_cortes[i].t++;
            if (sm_ult_timer <= 0)
            {
                sm_ult_fase = 0;
                sm_ult_cortes = [];
            }
        break;
    }
}

// Draw GUI de obj_mec_golpe: oscurece la pantalla, dibuja los cortes y el destello
function mec_swordmaster_ultimate_dibujar()
{
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();

    if (sm_ult_fase > 0)
    {
        // Mundo -> GUI (la cámara puede estar sacudiéndose)
        var _vx = 0, _vy = 0, _ex = 1, _ey = 1;
        if (view_camera[0] != -1)
        {
            _vx = camera_get_view_x(view_camera[0]);
            _vy = camera_get_view_y(view_camera[0]);
            _ex = _gw / camera_get_view_width(view_camera[0]);
            _ey = _gh / camera_get_view_height(view_camera[0]);
        }

        var _oscuro = (sm_ult_fase == 1) ? min(0.6, (sm_ult_preparacion - sm_ult_timer) / 10 * 0.6) : 0.6 * sm_ult_timer / 30;
        draw_set_color(c_black);
        draw_set_alpha(_oscuro);
        draw_rectangle(0, 0, _gw, _gh, false);

        gpu_set_blendmode(bm_add);
        draw_set_color(make_color_rgb(0, 230, 255));
        for (var i = 0; i < array_length(sm_ult_cortes); i++)
        {
            var _c = sm_ult_cortes[i];
            var _crece = min(1, _c.t / 3);                                   // el corte se abre en 3 frames
            var _a = (sm_ult_fase == 1) ? 0.9 : 0.9 * sm_ult_timer / 30;
            var _l = _c.largo * _crece / 2;
            var _x1 = (_c.x + lengthdir_x(_l, _c.ang) - _vx) * _ex;
            var _y1 = (_c.y + lengthdir_y(_l, _c.ang) - _vy) * _ey;
            var _x2 = (_c.x - lengthdir_x(_l, _c.ang) - _vx) * _ex;
            var _y2 = (_c.y - lengthdir_y(_l, _c.ang) - _vy) * _ey;
            draw_set_alpha(_a * 0.35);
            draw_line_width(_x1, _y1, _x2, _y2, 5);
            draw_set_alpha(_a);
            draw_line_width(_x1, _y1, _x2, _y2, 1);
        }
        gpu_set_blendmode(bm_normal);
    }

    if (sm_ult_flash > 0)
    {
        draw_set_color(c_white);
        draw_set_alpha(sm_ult_flash / 12 * 0.8);
        draw_rectangle(0, 0, _gw, _gh, false);
    }

    // Barra de carga (solo en Swordmaster), arriba a la derecha bajo el texto del estilo
    if (global.estilo == Estilo.SWORDMASTER)
    {
        var _ancho = 180;
        var _x2b = _gw - 16;
        var _x1b = _x2b - _ancho;
        var _yb = 78;
        var _llena = mec_swordmaster_ultimate_lista();
        draw_set_alpha(0.6);
        draw_set_color(c_black);
        draw_rectangle(_x1b, _yb, _x2b, _yb + 8, false);
        draw_set_alpha(_llena ? 0.7 + 0.3 * abs(sin(current_time / 120)) : 1);
        draw_set_color(_llena ? c_white : make_color_rgb(0, 230, 255));
        draw_rectangle(_x1b, _yb, _x1b + _ancho * sm_ult_carga / sm_ult_max, _yb + 8, false);
        draw_set_alpha(1);
        draw_set_halign(fa_right);
        draw_set_color(_llena ? c_white : c_ltgray);
        draw_text(_x2b, _yb + 12, _llena ? "ULTIMATE LISTO: F" : "Ultimate");
        draw_set_halign(fa_left);
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
}
