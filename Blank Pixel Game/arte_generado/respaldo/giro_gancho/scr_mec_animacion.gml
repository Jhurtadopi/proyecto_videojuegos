// ==============================
// ANIMACIÓN DEL JUGADOR
// Elige el sprite de obj_jugador según lo que está haciendo y lo voltea según "mirando".
// Corre en el End Step de obj_mecanicas_jugador, después de todas las mecánicas.
// La colisión no cambia: obj_jugador usa spr_hurtbox (32x64, simétrica) como máscara.
//
// VOLTERETAS (estilo Sanabi): una vuelta completa sobre el centro del cuerpo
//   - Shift mientras se balancea en el gancho (el boost)  -> vuelta hacia donde va el balanceo
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

    // --- Disparadores de voltereta ---
    if (gancho_estado == GanchoEstado.BALANCEANDO && keyboard_check_pressed(vk_shift))
    {
        var _dir_balanceo = (abs(gancho_vx) > 0.5) ? sign(gancho_vx) : mirando;
        mec_animacion_iniciar_giro(_dir_balanceo, giro_duracion_gancho);
    }
    else if (salto_extra_este_frame)
    {
        var _dir_salto;
        if (walljump_bloqueo == walljump_bloqueo_max) _dir_salto = walljump_dir;   // salto en pared
        else _dir_salto = keyboard_check(ord("D")) - keyboard_check(ord("A"));    // doble salto
        mec_animacion_iniciar_giro(_dir_salto, giro_duracion_salto);
    }

    // La vuelta se corta al aterrizar, al golpear o al hacer dash
    if (giro_timer > 0 && (_suelo || mec_parry_golpeando() || mec_dash_activo()))
    {
        giro_timer = 0;
    }

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

    var _se_movio = abs(_j.x - x_inicio) > 0.5;
    var _spr;
    var _vel = 1;

    if (mec_parry_golpeando())
    {
        _spr = spr_jugador_ataque;
        _vel = 0;
    }
    else if (mec_dash_activo())
    {
        _spr = spr_jugador_dash;
    }
    else if (giro_timer > 0 || !_suelo || mec_gancho_activo())
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

    if (_j.sprite_index != _spr)
    {
        _j.sprite_index = _spr;
        _j.image_index = 0;
    }

    // Ataque: los cuadros siguen el avance del golpe (dura parry_duracion frames)
    if (_spr == spr_jugador_ataque)
    {
        var _n = sprite_get_number(spr_jugador_ataque);
        var _avance = (parry_duracion - parry_timer) / parry_duracion;
        _j.image_index = min(_n - 1, floor(_avance * _n));
    }

    // Salto: cuadro 0 subiendo, cuadro 1 cayendo (durante la vuelta, siempre el 0: más compacto)
    if (_spr == spr_jugador_salto) _j.image_index = (giro_timer > 0 || _j.vsp < 0) ? 0 : 1;

    _j.image_speed = _vel;

    // Durante la vuelta, el sprite normal se oculta y lo dibuja mec_animacion_dibujar
    _j.visible = (giro_timer <= 0 && giro_angulo == 0);

    // --- Estela del dash ---
    for (var i = array_length(estela) - 1; i >= 0; i--)
    {
        estela[i].vida--;
        if (estela[i].vida <= 0) array_delete(estela, i, 1);
    }

    if (mec_dash_activo())
    {
        if (estela_contador mod estela_cada == 0)
        {
            array_push(estela, { x: _j.x, y: _j.y, spr: _j.sprite_index, img: _j.image_index,
                                 xs: _j.image_xscale, vida: estela_vida });
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
function mec_animacion_dibujar()
{
    var _j = jugador;
    if (_j == noone || !instance_exists(_j) || _j.visible) return;

    var _mitad = _j.sprite_height / 2;
    var _cx = _j.x;
    var _cy = _j.y - _mitad;
    var _px = _cx + lengthdir_x(_mitad, 270 + giro_angulo);
    var _py = _cy + lengthdir_y(_mitad, 270 + giro_angulo);

    draw_sprite_ext(_j.sprite_index, _j.image_index, _px, _py,
                    _j.image_xscale, _j.image_yscale, giro_angulo, _j.image_blend, _j.image_alpha);
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

        draw_sprite_ext(_g.spr, _g.img, _g.x, _g.y, _g.xs, _ys, 0, c_white, _a);

        // Copia desplazada 2 px hacia atrás: toque de holograma / glitch
        draw_sprite_ext(_g.spr, _g.img, _g.x - _g.xs * 2, _g.y, _g.xs, _ys, 0, c_white, _a * 0.35);
    }

    gpu_set_fog(false, c_black, 0, 0);
    gpu_set_blendmode(bm_normal);
}
