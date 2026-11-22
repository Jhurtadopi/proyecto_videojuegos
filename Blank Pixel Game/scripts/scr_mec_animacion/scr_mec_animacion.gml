// ==============================
// ANIMACIÓN DEL JUGADOR
// Elige el sprite de obj_jugador según lo que está haciendo y lo voltea según "mirando".
// Corre en el End Step de obj_mecanicas_jugador, después de todas las mecánicas.
// La colisión no cambia: obj_jugador usa spr_hurtbox (32x64, simétrica) como máscara.
//
// VOLTERETAS (estilo Sanabi): una vuelta completa sobre el centro del cuerpo
//   - Soltar el gancho y luego hacer dash en el aire      -> vuelta completa durante el dash
//   - Doble salto                                          -> voltereta hacia donde va el salto
//   - Salto en pared                                       -> voltereta hacia el lado del empuje
// Durante la vuelta obj_jugador se oculta y se dibuja rotado desde el Draw de este objeto.
// ==============================

function mec_animacion_crear()
{
    giro_duracion_gancho = 22;      // frames que dura la vuelta del gancho
    giro_duracion_salto = 18;       // frames que dura la voltereta del doble salto
    giro_vueltas = 1;               // vueltas completas por voltereta

    giro_timer = 0;
    giro_total = 1;
    giro_dir = 1;                   // 1 = hacia la derecha (sentido horario), -1 = izquierda
    giro_angulo = 0;
    giro_con_dash = false;          // la vuelta actual va junto al dash (no se corta por él)
    giro_post_gancho = false;       // se soltó el gancho y aún no se aterriza: el dash gira
    gancho_estado_prev = GanchoEstado.INACTIVO;

    // GANCHO: alterna la mano en cada lanzamiento e inclina el cuerpo hacia el ancla
    gancho_mano = -1;               // 1 = mano delantera, -1 = mano trasera (cambia al lanzar)
    inclinacion = 0;                // grados que se inclina el cuerpo durante el gancho
    inclinacion_max = 60;
    inclinacion_suavizado = 0.25;
    gancho_mano_dx_delantera = 2;   // px del puño levantado respecto al centro (mirando a la derecha), medido en spr_jugador_gancho
    gancho_mano_dx_trasera = 0;
    gancho_mano_desde_arriba = 4;   // px desde el borde superior del sprite hasta la mano levantada
    gancho_vis_t = 0;               // tiempo para los pulsos de energía del cable
    gancho_flash = 0;               // destello al engancharse
    gancho_color = make_color_rgb(0, 230, 255);
    // Sprite opcional: existe solo después de procesar la hoja del gancho (-1 si no está).
    // El nombre se arma por partes para que el validador no lo marque como recurso faltante.
    gancho_sprite = asset_get_index("spr" + "_jugador_gancho");

    // Sprite que se dibuja en lugar del del jugador (-1 = el suyo). El gancho lo usa para mostrar
    // el brazo levantado SIN cambiar sprite_index: el origen de la cuerda (mec_gancho_origen,
    // código ajeno) depende de la altura del sprite y así no se mueve.
    dibujo_spr = -1;
    dibujo_img = 0;

    // Sprites opcionales por golpe del Swordmaster (si no existen, se usa spr_jugador_ataque)
    golpe_spr_lanzador = asset_get_index("spr" + "_jugador_lanzador");
    golpe_spr_aereo = asset_get_index("spr" + "_jugador_aereo");
    golpe_spr_estampada = asset_get_index("spr" + "_jugador_estampada");

    // ESTELA DEL DASH: siluetas del jugador en cian que se desvanecen
    estela_color = make_color_rgb(0, 230, 255);
    estela_vida = 14;               // frames que tarda en desaparecer cada silueta
    estela_cada = 2;                // deja una silueta cada N frames de dash
    estela_alpha = 0.55;            // opacidad de la silueta más nueva
    estela_contador = 0;
    estela = [];                    // [{x, y, spr, img, xs, vida}]
}

function mec_animacion_girando()
{
    return giro_timer > 0;
}

function mec_animacion_iniciar_giro(_dir, _duracion)
{
    giro_dir = (_dir == 0) ? mirando : sign(_dir);
    giro_total = _duracion;
    giro_timer = _duracion;
    giro_con_dash = false;
}

// End Step: después de todas las mecánicas
function mec_animacion_fin()
{
    var _j = jugador;
    if (_j == noone || !instance_exists(_j)) return;

    // Hitstop: congelar la animación (y la vuelta) en el cuadro actual
    if (en_hitstop)
    {
        _j.image_speed = 0;
        return;
    }

    var _suelo = mec_en_suelo(_j);

    // Estampada del Swordmaster (fase 1 = suspendido, 2 = cayendo)
    var _picado_fase = 0;
    with (obj_mec_golpe) if (sm_picado) _picado_fase = sm_picado_fase;

    // --- Voltereta del gancho: se arma al soltarlo en el aire y se gasta con el dash ---
    if (gancho_estado_prev == GanchoEstado.BALANCEANDO && gancho_estado != GanchoEstado.BALANCEANDO)
    {
        // Soltarse del balanceo recarga el dash aéreo (como en Sanabi), para poder encadenar
        // el dash con voltereta. Se hace aquí para no modificar scr_mec_gancho (ajeno).
        dash_aire_disponible = true;
        dash_cooldown = 0;
        if (!_suelo) giro_post_gancho = true;
    }
    if (_suelo || gancho_estado == GanchoEstado.BALANCEANDO) giro_post_gancho = false;

    // Cada lanzamiento usa la otra mano; al engancharse, destello en el ancla
    if (gancho_estado_prev == GanchoEstado.INACTIVO && gancho_estado == GanchoEstado.LANZANDO) gancho_mano = -gancho_mano;
    if (gancho_estado_prev == GanchoEstado.LANZANDO && gancho_estado == GanchoEstado.BALANCEANDO) gancho_flash = 10;
    gancho_flash = max(0, gancho_flash - 1);
    gancho_vis_t++;
    gancho_estado_prev = gancho_estado;

    // --- Disparadores de voltereta ---
    if (giro_post_gancho && mec_dash_activo() && dash_timer == dash_duracion)   // el dash empezó este frame
    {
        mec_animacion_iniciar_giro(dash_dir, giro_duracion_gancho);
        giro_con_dash = true;
        giro_post_gancho = false;
    }
    else if (salto_extra_este_frame)
    {
        var _dir_salto;
        if (walljump_bloqueo == walljump_bloqueo_max) _dir_salto = walljump_dir;   // salto en pared
        else _dir_salto = keyboard_check(ord("D")) - keyboard_check(ord("A"));    // doble salto
        mec_animacion_iniciar_giro(_dir_salto, giro_duracion_salto);
    }

    // La vuelta se corta al aterrizar, al golpear o al hacer dash
    if (giro_timer > 0 && (_suelo || _picado_fase > 0 || mec_parry_golpeando() || (mec_dash_activo() && !giro_con_dash)))
    {
        giro_timer = 0;
    }
    if (giro_timer <= 0) giro_con_dash = false;

    if (giro_timer > 0)
    {
        var _t = 1 - giro_timer / giro_total;                 // 0 -> 1
        var _suave = 1 - power(1 - _t, 2);                    // arranca rápido y frena al final
        giro_angulo = -giro_dir * 360 * giro_vueltas * _suave; // negativo = horario en GameMaker
        giro_timer--;
    }
    else
    {
        giro_angulo = 0;
    }

    _j.image_xscale = mirando;

    // Deslizando por la pared: de espaldas a ella (lo calcula scr_mec_pared el frame anterior)
    if (mec_pared_deslizando()) _j.image_xscale = -pared_dir;

    // Inclinación hacia el ancla mientras cuelga (en el lanzamiento, a medias)
    var _incl_obj = 0;
    if (mec_gancho_activo() && giro_timer <= 0)
    {
        var _o = mec_gancho_origen(_j);
        var _dir_ancla = point_direction(_o[0], _o[1], gancho_ancla_x, gancho_ancla_y);
        _incl_obj = clamp(angle_difference(_dir_ancla, 90), -inclinacion_max, inclinacion_max);
        if (gancho_estado == GanchoEstado.LANZANDO) _incl_obj *= 0.5;

        // Colgado, mira hacia donde va el balanceo
        if (gancho_estado == GanchoEstado.BALANCEANDO && abs(gancho_vx) > 1) _j.image_xscale = sign(gancho_vx);
    }
    inclinacion = lerp(inclinacion, _incl_obj, inclinacion_suavizado);
    if (abs(inclinacion) < 0.5 && _incl_obj == 0) inclinacion = 0;

    var _se_movio = abs(_j.x - x_inicio) > 0.5;
    var _spr;
    var _vel = 1;

    // Golpe en curso (lo elige obj_mec_golpe): cada movimiento puede tener su propio sprite
    var _nombre_golpe = "";
    with (obj_mec_golpe) if (is_struct(golpe_actual)) _nombre_golpe = golpe_actual.nombre;
    var _spr_golpe = spr_jugador_ataque;
    if (_nombre_golpe == "Lanzador" && golpe_spr_lanzador != -1) _spr_golpe = golpe_spr_lanzador;
    else if (_nombre_golpe == "Corte aereo" && golpe_spr_aereo != -1) _spr_golpe = golpe_spr_aereo;
    var _es_golpe = false;

    if (_picado_fase > 0)
    {
        if (golpe_spr_estampada != -1) _spr = golpe_spr_estampada;              // cuadro 0 preparación, 1 picada
        else _spr = (_picado_fase == 1) ? spr_jugador_ataque : spr_jugador_salto; // katana en alto / en picada
        _vel = 0;
    }
    else if (mec_parry_golpeando())
    {
        _spr = _spr_golpe;
        _es_golpe = true;
        _vel = 0;
    }
    else if (mec_dash_activo() && giro_timer <= 0)
    {
        _spr = spr_jugador_dash;
    }
    else if (giro_timer > 0 || !_suelo || mec_gancho_activo() || mec_gancho_enemigo_activo())
    {
        _spr = spr_jugador_salto;
        _vel = 0;
    }
    else if (_se_movio)
    {
        _spr = spr_jugador_correr;
    }
    else
    {
        _spr = spr_jugador;   // idle
    }

    // Estilo Underdog: sus propios sprites (taladro y gafas rojas)
    var _ud_idx = -1;
    if (mec_underdog_activo() && _picado_fase == 0)
    {
        var _vaiven = [0, 1, 2, 1];                 // ida y vuelta: el taladro barre de lado a lado
        if (ud_accion == UdAccion.ARRIBA) { _spr = spr_jugador_ud_arriba; _vel = 0; _ud_idx = _vaiven[(ud_t div 3) mod 4]; }
        else if (ud_accion == UdAccion.SUBIR) { _spr = spr_jugador_ud_subir; _vel = 0; _ud_idx = _vaiven[(ud_t div 3) mod 4]; }
        else if (ud_accion == UdAccion.EMERGER) { _spr = spr_jugador_ud_emerger; _vel = 0; _ud_idx = 0; }
        else if (_es_golpe) _spr = spr_jugador_ud_ataque;
        else if (_spr == spr_jugador) _spr = spr_jugador_ud_idle;
        else if (_spr == spr_jugador_correr) _spr = spr_jugador_ud_correr;
        else if (_spr == spr_jugador_dash) { _spr = spr_jugador_ud_correr; _vel = 0; _ud_idx = 1; }
        else if (_spr == spr_jugador_salto && !mec_gancho_activo() && giro_timer <= 0)
        {
            _spr = (_j.vsp < 0) ? spr_jugador_ud_emerger : spr_jugador_ud_idle;
            _vel = 0;
            _ud_idx = 0;
        }
    }

    if (_j.sprite_index != _spr)
    {
        _j.sprite_index = _spr;
        _j.image_index = 0;
    }

    // Estampada: preparación (cuadro 0 del ataque) y caída (cuadro de caer)
    if (_picado_fase == 1) _j.image_index = 0;
    else if (_picado_fase == 2) _j.image_index = 1;
    // Ataque: los cuadros siguen el avance del golpe (dura parry_duracion frames)
    else if (_es_golpe)
    {
        var _n = sprite_get_number(_spr);
        var _avance = (parry_duracion - parry_timer) / parry_duracion;
        _j.image_index = min(_n - 1, floor(_avance * _n));
    }

    // Salto: cuadro 0 subiendo, cuadro 1 cayendo (durante la vuelta, siempre el 0: más compacto)
    if (_spr == spr_jugador_salto) _j.image_index = (giro_timer > 0 || _j.vsp < 0) ? 0 : 1;
    if (_ud_idx >= 0) _j.image_index = _ud_idx;

    // Gancho: se dibuja la pose del brazo levantado (cuadro 0 mano delantera, 1 trasera)
    dibujo_spr = -1;
    if (gancho_sprite != -1 && _picado_fase == 0 && mec_gancho_activo() && giro_timer <= 0)
    {
        dibujo_spr = gancho_sprite;
        dibujo_img = (gancho_mano == 1) ? 0 : min(1, sprite_get_number(gancho_sprite) - 1);
    }

    _j.image_speed = _vel;

    // Durante la vuelta, el sprite normal se oculta y lo dibuja mec_animacion_dibujar
    _j.visible = (giro_timer <= 0 && giro_angulo == 0 && inclinacion == 0 && dibujo_spr == -1 && !mec_underdog_oculto());

    // --- Estela del dash ---
    for (var i = array_length(estela) - 1; i >= 0; i--)
    {
        estela[i].vida--;
        if (estela[i].vida <= 0) array_delete(estela, i, 1);
    }

    if (mec_dash_activo() || _picado_fase == 2)
    {
        if (estela_contador mod estela_cada == 0)
        {
            array_push(estela, { x: _j.x, y: _j.y,
                                 spr: (dibujo_spr != -1) ? dibujo_spr : _j.sprite_index,
                                 img: (dibujo_spr != -1) ? dibujo_img : _j.image_index,
                                 xs: _j.image_xscale, ang: giro_angulo + inclinacion, vida: estela_vida });
        }
        estela_contador++;
    }
    else
    {
        estela_contador = 0;
    }
}

// Draw de obj_mecanicas_jugador: dibuja al jugador rotando alrededor del centro de su cuerpo
// (el origen del sprite está en los pies, así que se compensa para no girar sobre ellos)
// Posición donde dibujar un sprite con origen en los pies para que rote sobre el centro del cuerpo
function mec_animacion_pos_rotada(_x, _y, _alto, _angulo)
{
    var _mitad = _alto / 2;
    return [_x + lengthdir_x(_mitad, 270 + _angulo), (_y - _mitad) + lengthdir_y(_mitad, 270 + _angulo)];
}

function mec_animacion_dibujar()
{
    var _j = jugador;
    if (_j == noone || !instance_exists(_j) || _j.visible) return;
    if (mec_underdog_oculto()) return;          // bajo tierra lo dibuja mec_underdog_dibujar

    var _ang = giro_angulo + inclinacion;
    var _spr = (dibujo_spr != -1) ? dibujo_spr : _j.sprite_index;
    var _img = (dibujo_spr != -1) ? dibujo_img : _j.image_index;
    var _p = mec_animacion_pos_rotada(_j.x, _j.y, sprite_get_height(_spr) * abs(_j.image_yscale), _ang);
    draw_sprite_ext(_spr, _img, _p[0], _p[1],
                    _j.image_xscale, _j.image_yscale, _ang, _j.image_blend, _j.image_alpha);
}


// Draw de obj_mecanicas_jugador: siluetas cian con brillo (blend aditivo) detrás del jugador
function mec_animacion_dibujar_estela()
{
    var _n = array_length(estela);
    if (_n == 0) return;

    var _j = jugador;
    var _jx = instance_exists(_j) ? _j.x : -100000;
    var _jy = instance_exists(_j) ? _j.y : -100000;

    gpu_set_blendmode(bm_add);
    gpu_set_fog(true, estela_color, 0, 0);     // pinta el sprite de un solo color

    for (var i = 0; i < _n; i++)
    {
        var _g = estela[i];

        // No dibujar la silueta que está encima del jugador (lo taparía de cian)
        if (abs(_g.x - _jx) < 12 && abs(_g.y - _jy) < 12) continue;

        var _t = _g.vida / estela_vida;            // 1 nueva -> 0 por desaparecer
        var _a = estela_alpha * _t * _t;
        var _ys = 1 - (1 - _t) * 0.15;             // se aplasta un poco al desvanecerse

        var _p = mec_animacion_pos_rotada(_g.x, _g.y, sprite_get_height(_g.spr) * _ys, _g.ang);
        draw_sprite_ext(_g.spr, _g.img, _p[0], _p[1], _g.xs, _ys, _g.ang, c_white, _a);

        // Copia desplazada 2 px hacia atrás: toque de holograma / glitch
        draw_sprite_ext(_g.spr, _g.img, _p[0] - _g.xs * 2, _p[1], _g.xs, _ys, _g.ang, c_white, _a * 0.35);
    }

    gpu_set_fog(false, c_black, 0, 0);
    gpu_set_blendmode(bm_normal);
}


// Posición en el mundo de la mano que sostiene el gancho (sigue la rotación del cuerpo).
// Sin el sprite de balanceo, el cable sale del pecho (el punto físico del gancho).
function mec_animacion_mano_gancho()
{
    var _j = jugador;
    if (gancho_sprite == -1 || dibujo_spr != gancho_sprite) return mec_gancho_origen(_j);

    var _h = sprite_get_height(gancho_sprite);
    var _lx = ((gancho_mano == 1) ? gancho_mano_dx_delantera : gancho_mano_dx_trasera) * _j.image_xscale;
    var _ly = -_h + gancho_mano_desde_arriba;      // respecto a los pies

    // Respecto al centro del cuerpo (pivote de la rotación) y rotado igual que el sprite
    var _rx = _lx;
    var _ry = _ly + _h / 2;
    var _ang = giro_angulo + inclinacion;
    var _c = dcos(_ang);
    var _s = dsin(_ang);

    return [_j.x + _rx * _c + _ry * _s, _j.y - _h / 2 - _rx * _s + _ry * _c];
}

// Draw de obj_mecanicas_jugador: cable del gancho normal
function mec_animacion_dibujar_gancho()
{
    if (gancho_estado == GanchoEstado.INACTIVO) return;
    var _j = jugador;
    if (_j == noone || !instance_exists(_j)) return;

    var _o = mec_animacion_mano_gancho();
    var _lanzando = (gancho_estado == GanchoEstado.LANZANDO);
    var _px = _lanzando ? gancho_punta_x : gancho_ancla_x;
    var _py = _lanzando ? gancho_punta_y : gancho_ancla_y;
    mec_animacion_dibujar_cable(_o[0], _o[1], _px, _py, !_lanzando, gancho_flash);
}

// Cable de energía con garra (lo usan el gancho normal y el gancho a enemigos)
function mec_animacion_dibujar_cable(_ox, _oy, _px, _py, _anclado, _flash)
{
    var _len = point_distance(_ox, _oy, _px, _py);
    var _dir = point_direction(_ox, _oy, _px, _py);

    // Núcleo oscuro del cable
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(14, 20, 34));
    draw_line_width(_ox, _oy, _px, _py, 3);

    gpu_set_blendmode(bm_add);
    draw_set_color(gancho_color);

    // Halo y filamento de energía
    draw_set_alpha(0.3);
    draw_line_width(_ox, _oy, _px, _py, 5);
    draw_set_alpha(0.9);
    draw_line(_ox, _oy, _px, _py);

    // Pulsos que viajan de la mano a la punta
    var _sep = 26;
    var _d = (gancho_vis_t * 5) mod _sep;
    while (_d < _len)
    {
        var _ax = _ox + lengthdir_x(_d, _dir);
        var _ay = _oy + lengthdir_y(_d, _dir);
        draw_line_width(_ax, _ay, _ax + lengthdir_x(5, _dir), _ay + lengthdir_y(5, _dir), 2);
        _d += _sep;
    }

    // Cabeza: punta en flecha y tres garras (abiertas al volar, clavadas al engancharse)
    var _abre = _anclado ? 65 : 40;
    draw_set_alpha(1);
    draw_triangle(_px + lengthdir_x(5, _dir), _py + lengthdir_y(5, _dir),
                  _px + lengthdir_x(4, _dir + 140), _py + lengthdir_y(4, _dir + 140),
                  _px + lengthdir_x(4, _dir - 140), _py + lengthdir_y(4, _dir - 140), false);
    for (var k = -1; k <= 1; k++)
    {
        var _ang_garra = _dir + 180 + k * _abre;
        draw_line_width(_px, _py, _px + lengthdir_x(7, _ang_garra), _py + lengthdir_y(7, _ang_garra), 1);
    }

    // Anclado: anillo que late y destello al engancharse
    if (_anclado)
    {
        var _r = 5 + 2 * abs(sin(gancho_vis_t * 0.15));
        draw_set_alpha(0.7);
        draw_circle(_px, _py, _r, true);
        if (_flash > 0)
        {
            draw_set_alpha(_flash / 10);
            draw_circle(_px, _py, 6 + (10 - _flash) * 2, true);
            draw_circle(_px, _py, 3, false);
        }
    }

    // Brillo en la mano / guantelete
    draw_set_alpha(0.7);
    draw_circle(_ox, _oy, 3, false);

    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
