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
