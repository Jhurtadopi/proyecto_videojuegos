// ==============================
// ESTILO UNDERDOG (taladro). Contexto: obj_mecanicas_jugador.
// Bajo tierra el jugador sigue en la superficie (sobre el suelo) pero se oculta, no recibe golpes
// (su hurtbox se desactiva) y se dibuja como silueta excavando. No modifica obj_jugador ni obj_enemigo:
// solo escribe variables en tiempo de ejecución.
//
//   Superficie: S = excavar | click = taladrazo | W + click = taladro hacia arriba (multigolpe)
//   Bajo tierra: A/D mover | Shift = dash dirigible | Espacio = emerger golpeando hacia arriba
//                click = pinchazo hacia arriba (o ARRASTRE si encima hay un enemigo recién estampado)
//                W + click = perforación: sube taladrando con el enemigo
// ==============================

enum UdAccion
{
    NINGUNA,
    ENTRAR,         // se hunde en el suelo
    ARRIBA,         // W + click en la superficie: taladra hacia arriba
    SUBIR,          // W + click bajo tierra: sale subiendo y taladrando
    EMERGER,        // Espacio bajo tierra: sale de golpe
    ARRASTRE        // click bajo un enemigo estampado: lo entierra y lo expulsa
}

function mec_underdog_crear()
{
    ud_bajo_tierra = false;
    ud_accion = UdAccion.NINGUNA;
    ud_timer = 0;
    ud_tick = 0;
    ud_t = 0;                       // reloj para animaciones y partículas
    ud_hurtbox = noone;             // hurtbox del jugador desactivada mientras está bajo tierra

    // Movimiento bajo tierra
    ud_vel_bajo = 4;                // px/frame con A/D
    ud_profundidad_dibujo = 26;     // px bajo la superficie donde se dibuja la silueta
    ud_entrar_frames = 10;

    // Dash bajo tierra (dirigible con A/D durante el dash)
    ud_dash_vel = 10;
    ud_dash_frames = 18;
    ud_dash_cooldown_max = 30;
    ud_dash_timer = 0;
    ud_dash_dir = 1;
    ud_dash_cooldown = 0;

    // Emerger (Espacio)
    ud_emerger_vsp = -10;
    ud_emerger_danio = 8;
    ud_emerger_ky = -12;
    ud_emerger_stagger = 40;

    // Taladro hacia arriba (W + click): golpes repetidos sosteniendo al enemigo sobre la punta
    ud_zona_arriba = [-30, 30, -130, -30];  // [x desde, x hasta, y desde, y hasta] respecto a los pies
    ud_arriba_frames = 30;          // en la superficie
    ud_subir_frames = 24;           // desde bajo tierra
    ud_subir_vsp = -11;
    ud_tick_cada = 4;               // frames entre golpes
    ud_tick_danio = 2;
    ud_tick_stagger = 20;
    ud_altura_sostener = 72;        // px sobre los pies donde se sostiene al enemigo
    ud_final_danio = 8;
    ud_final_ky = -12;
    ud_final_stagger = 45;

    // Arrastre (conexión con la estampada del Swordmaster)
    ud_arrastre_frames = 45;
    ud_arrastre_danio = 15;
    ud_arrastre_ky = -13;
    ud_arrastre_stagger = 50;
    ud_arrastre_rango_x = 48;
    ud_arrastre_objetivo = noone;

    ud_particulas = [];             // tierra: [{x, y, vx, vy, t}]
    ud_color_tierra = make_color_rgb(110, 78, 52);
}

function mec_underdog_activo()
{
    return global.estilo == Estilo.UNDERDOG;
}

// El jugador se dibuja con la silueta subterránea (oculto su sprite normal)
function mec_underdog_oculto()
{
    return ud_bajo_tierra || ud_accion == UdAccion.ENTRAR;
}

function mec_underdog_particulas(_x, _y, _n, _fuerza)
{
    repeat (_n)
    {
        array_push(ud_particulas, { x: _x + random_range(-10, 10), y: _y - 1,
            vx: random_range(-2.5, 2.5) * _fuerza, vy: -random_range(1.5, 5) * _fuerza, t: irandom_range(18, 30) });
    }
}

function mec_underdog_enterrar()
{
    var _j = jugador;
    ud_bajo_tierra = true;
    ud_dash_timer = 0;
    ud_hurtbox = variable_instance_exists(_j, "hurtbox") ? _j.hurtbox : noone;
    if (instance_exists(ud_hurtbox)) instance_deactivate_object(ud_hurtbox);   // invulnerable bajo tierra
    mec_underdog_particulas(_j.x, _j.y, 10, 1);
    with (obj_camara) aplicar_temblor(2, 8);
}

// Sale a la superficie. Con _golpe, golpea hacia arriba (Espacio)
function mec_underdog_salir(_golpe)
{
    if (!ud_bajo_tierra) return;
    var _j = jugador;
    ud_bajo_tierra = false;
    ud_dash_timer = 0;
    if (ud_hurtbox != noone) instance_activate_object(ud_hurtbox);
    ud_hurtbox = noone;
    mec_underdog_particulas(_j.x, _j.y, 14, 1.3);
    instance_create_layer(_j.x, _j.y, "Instances", obj_fx_estampada, { fuerza: 0.3, radio: 46 });

    if (_golpe)
    {
        _j.vsp = ud_emerger_vsp;
        ud_accion = UdAccion.EMERGER;
        ud_timer = 14;
        mec_underdog_golpe_arriba(true, ud_emerger_danio, ud_emerger_ky, ud_emerger_stagger);
    }
}

// Enemigos dentro de la zona sobre la cabeza del jugador
function mec_underdog_enemigos_arriba()
{
    var _j = jugador;
    var _z = ud_zona_arriba;
    var _lista = ds_list_create();
    var _n = collision_rectangle_list(_j.x + _z[0], _j.y + _z[2], _j.x + _z[1], _j.y + _z[3], obj_enemigo, false, true, _lista, false);
    var _res = [];
    for (var i = 0; i < _n; i++) array_push(_res, _lista[| i]);
    ds_list_destroy(_lista);
    return _res;
}

// Un golpe del taladro hacia arriba. No final: daña y sostiene al enemigo sobre la punta.
// Final: lo lanza hacia arriba.
function mec_underdog_golpe_arriba(_final, _danio, _ky, _stagger)
{
    var _j = jugador;
    var _objetivos = mec_underdog_enemigos_arriba();
    var _jx = _j.x;
    var _jy = _j.y;
    var _alto = ud_altura_sostener;
    var _kx = mirando * 2;

    for (var i = 0; i < array_length(_objetivos); i++)
    {
        var _e = _objetivos[i];
        if (!instance_exists(_e) || !_e.visible) continue;

        with (_e)
        {
            if (_final)
            {
                recibir_impacto(_danio, _kx, _ky, _stagger);
            }
            else
            {
                recibir_impacto(_danio, 0, 0, _stagger);
                if (instance_exists(id) && lanzable)
                {
                    // Lo centra sobre el taladro y lo mantiene a la altura de la punta
                    x = lerp(x, _jx, 0.4);
                    hsp = 0;
                    vsp = clamp(((_jy - _alto) - y) * 0.35, -8, 8) - gravedad_enemigo;
                    estado = EnemyState.AIRBORNE;
                }
            }
        }
    }

    if (array_length(_objetivos) > 0)
    {
        var _hs = _final ? 6 : 2;
        var _tf = _final ? 6 : 2;
        var _tt = _final ? 14 : 4;
        with (obj_controladores) aplicar_hitstop(_hs);
        with (obj_camara) aplicar_temblor(_tf, _tt);
        mec_underdog_particulas(_jx, _jy - 90, _final ? 6 : 2, 0.8);
    }
}

// Enemigo recién estampado (ventana conexion_underdog_timer) justo encima del jugador
function mec_underdog_buscar_arrastre()
{
    var _j = jugador;
    var _mejor = noone;
    var _dmin = ud_arrastre_rango_x;
    with (obj_enemigo)
    {
        if (variable_instance_exists(id, "conexion_underdog_timer") && conexion_underdog_timer > 0 && visible
            && abs(y - _j.y) <= 24 && abs(x - _j.x) <= _dmin)
        {
            _mejor = id;
            _dmin = abs(x - _j.x);
        }
    }
    return _mejor;
}

// Begin Step: ANTES de las demás mecánicas (así puede bloquear el dash y el gancho normales)
function mec_underdog_inicio()
{
    var _j = jugador;
    ud_t++;
    ud_dash_cooldown = max(0, ud_dash_cooldown - 1);

    if (!mec_underdog_activo())
    {
        // Cambiar de estilo bajo tierra lo saca a la superficie
        if (ud_bajo_tierra) mec_underdog_salir(false);
        if (ud_accion != UdAccion.ARRASTRE) ud_accion = UdAccion.NINGUNA;
        return;
    }

    var _click = mouse_check_button_pressed(mb_left);
    var _w = keyboard_check(ord("W"));

    if (ud_bajo_tierra)
    {
        // Bajo tierra no hay dash normal ni gancho
        dash_cooldown = max(dash_cooldown, 2);
        gancho_cooldown = max(gancho_cooldown, 2);

        if (ud_accion != UdAccion.NINGUNA) return;

        if (keyboard_check_pressed(vk_shift) && ud_dash_timer == 0 && ud_dash_cooldown == 0)
        {
            var _in = keyboard_check(ord("D")) - keyboard_check(ord("A"));
            ud_dash_dir = (_in != 0) ? _in : mirando;
            ud_dash_timer = ud_dash_frames;
            ud_dash_cooldown = ud_dash_cooldown_max;
        }

        if (_click && _w)
        {
            // Perforación: sale subiendo y taladrando
            mec_underdog_salir(false);
            _j.vsp = ud_subir_vsp;
            ud_accion = UdAccion.SUBIR;
            ud_timer = ud_subir_frames;
            ud_tick = 0;
        }
        else if (_click)
        {
            var _e = mec_underdog_buscar_arrastre();
            if (_e != noone)
            {
                // Arrastre: lo hunde en el suelo y lo expulsa después
                ud_arrastre_objetivo = _e;
                ud_accion = UdAccion.ARRASTRE;
                ud_timer = ud_arrastre_frames;
                _e.visible = false;
                _e.conexion_underdog_timer = 0;
                mec_underdog_particulas(_e.x, _e.y, 12, 1.2);
                with (obj_camara) aplicar_temblor(3, 10);
            }
        }
        else if (keyboard_check_pressed(vk_space))
        {
            mec_underdog_salir(true);
        }
        return;
    }

    if (ud_accion != UdAccion.NINGUNA) return;

    var _suelo = mec_en_suelo(_j);
    var _libre = !mec_parry_golpeando() && !mec_dash_activo() && !mec_gancho_activo() && !mec_gancho_enemigo_activo();

    if (_click && _w && _suelo)
    {
        ud_accion = UdAccion.ARRIBA;
        ud_timer = ud_arriba_frames;
        ud_tick = 0;
    }
    else if (keyboard_check_pressed(ord("S")) && _suelo && _libre)
    {
        ud_accion = UdAccion.ENTRAR;
        ud_timer = ud_entrar_frames;
    }
}

// End Step: después del movimiento de obj_jugador y de las demás mecánicas
function mec_underdog_fin()
{
    var _j = jugador;

    // Partículas de tierra
    for (var i = array_length(ud_particulas) - 1; i >= 0; i--)
    {
        var _p = ud_particulas[i];
        _p.vy += 0.35;
        _p.x += _p.vx;
        _p.y += _p.vy;
        _p.t--;
        if (_p.t <= 0) array_delete(ud_particulas, i, 1);
    }

    switch (ud_accion)
    {
        case UdAccion.ENTRAR:
            _j.x = x_inicio;
            _j.y = y_inicio;
            _j.vsp = 0;
            ud_timer--;
            if (ud_timer <= 0)
            {
                ud_accion = UdAccion.NINGUNA;
                mec_underdog_enterrar();
            }
        break;

        case UdAccion.ARRIBA:
            _j.x = x_inicio;                        // quieto mientras taladra
            ud_tick++;
            ud_timer--;
            if (ud_timer <= 0)
            {
                mec_underdog_golpe_arriba(true, ud_final_danio, ud_final_ky, ud_final_stagger);
                ud_accion = UdAccion.NINGUNA;
            }
            else if (ud_tick mod ud_tick_cada == 0)
            {
                mec_underdog_golpe_arriba(false, ud_tick_danio, 0, ud_tick_stagger);
            }
        break;

        case UdAccion.SUBIR:
            ud_tick++;
            ud_timer--;
            if (ud_timer <= 0 || _j.vsp >= 0)
            {
                mec_underdog_golpe_arriba(true, ud_final_danio, ud_final_ky, ud_final_stagger);
                ud_accion = UdAccion.NINGUNA;
            }
            else if (ud_tick mod ud_tick_cada == 0)
            {
                mec_underdog_golpe_arriba(false, ud_tick_danio, 0, ud_tick_stagger);
            }
        break;

        case UdAccion.EMERGER:
            ud_timer--;
            if (ud_timer <= 0) ud_accion = UdAccion.NINGUNA;
        break;

        case UdAccion.ARRASTRE:
            var _e = ud_arrastre_objetivo;
            ud_timer--;
            if (!instance_exists(_e))
            {
                ud_accion = UdAccion.NINGUNA;
                break;
            }
            // Queda enterrado bajo el jugador, aturdido
            _e.x = lerp(_e.x, _j.x, 0.2);
            _e.hsp = 0;
            _e.vsp = -_e.gravedad_enemigo;
            _e.aturdido_timer = max(_e.aturdido_timer, 5);
            if (ud_t mod 3 == 0) mec_underdog_particulas(_e.x, _e.y, 1, 0.6);

            if (ud_timer <= 0)
            {
                // Expulsión: sale disparado hacia arriba
                _e.visible = true;
                var _d = ud_arrastre_danio;
                var _ky = ud_arrastre_ky;
                var _st = ud_arrastre_stagger;
                with (_e) recibir_impacto(_d, 0, _ky, _st);
                if (instance_exists(_e))
                {
                    mec_underdog_particulas(_e.x, _e.y, 16, 1.5);
                    instance_create_layer(_e.x, _e.y, "Instances", obj_fx_estampada, { fuerza: 0.6, radio: 70 });
                }
                with (obj_controladores) aplicar_hitstop(6);
                with (obj_camara) aplicar_temblor(7, 16);
                ud_arrastre_objetivo = noone;
                ud_accion = UdAccion.NINGUNA;
            }
        break;
    }

    if (!ud_bajo_tierra) return;

    // Movimiento bajo tierra: reemplaza lo que hizo obj_jugador (caminar, saltar, gravedad)
    var _in = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    var _dx = 0;
    if (ud_accion == UdAccion.NINGUNA)
    {
        if (ud_dash_timer > 0)
        {
            if (_in != 0) ud_dash_dir = _in;        // dash dirigible
            _dx = ud_dash_dir * ud_dash_vel;
            ud_dash_timer--;
        }
        else
        {
            _dx = _in * ud_vel_bajo;
        }
    }

    _j.x = x_inicio;
    _j.y = y_inicio;
    _j.hsp = 0;
    _j.vsp = 0;
    if (_dx != 0)
    {
        mirando = sign(_dx);
        mec_mover_hasta_x(_j, x_inicio + _dx);
        if (ud_t mod 2 == 0) mec_underdog_particulas(_j.x - mirando * 6, _j.y, 1, (ud_dash_timer > 0) ? 1.4 : 0.8);
    }

    // Se acabó el suelo (borde de una plataforma): sale y cae
    if (!mec_en_suelo(_j)) mec_underdog_salir(false);
}

// Draw: silueta excavando, montículo en la superficie, enemigo enterrado y partículas
function mec_underdog_dibujar()
{
    var _j = jugador;

    if (instance_exists(_j) && (ud_bajo_tierra || ud_accion == UdAccion.ENTRAR))
    {
        var _prof = ud_profundidad_dibujo;
        if (ud_accion == UdAccion.ENTRAR) _prof = ud_profundidad_dibujo * (1 - ud_timer / ud_entrar_frames);
        var _img = (ud_t div 4) mod sprite_get_number(spr_jugador_ud_excavar);

        // Silueta bajo tierra (como rayos X)
        draw_sprite_ext(spr_jugador_ud_excavar, _img, _j.x, _j.y + _prof, mirando, 1, 0, make_color_rgb(200, 170, 150), 0.75);

        // Montículo de tierra que se mueve con él
        var _salto = (ud_dash_timer > 0) ? 2 : abs(sin(ud_t * 0.4)) * 2;
        draw_set_color(ud_color_tierra);
        draw_ellipse(_j.x - 16, _j.y - 4 - _salto, _j.x + 16, _j.y + 3, false);
        draw_set_color(make_color_rgb(70, 48, 32));
        draw_ellipse(_j.x - 16, _j.y - 4 - _salto, _j.x + 16, _j.y + 3, true);

        // Brillo del taladro bajo tierra
        gpu_set_blendmode(bm_add);
        draw_set_color(make_color_rgb(0, 230, 255));
        draw_set_alpha(0.5 + 0.3 * abs(sin(ud_t * 0.5)));
        draw_circle(_j.x + mirando * 40, _j.y + _prof - 14, 3, false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }

    // Enemigo arrastrado bajo tierra
    if (ud_accion == UdAccion.ARRASTRE && instance_exists(ud_arrastre_objetivo))
    {
        var _e = ud_arrastre_objetivo;
        var _sacudida = (ud_t mod 4 < 2) ? 1 : -1;
        if (sprite_exists(_e.sprite_index))     // (algunos enemigos del equipo aún no tienen sprite)
            draw_sprite_ext(_e.sprite_index, 0, _e.x + _sacudida, _e.y + 30, _e.mirando, 1, 0, make_color_rgb(200, 150, 120), 0.6);
        draw_set_color(ud_color_tierra);
        draw_ellipse(_e.x - 20, _e.y - 6, _e.x + 20, _e.y + 3, false);
    }

    // Partículas de tierra
    draw_set_color(ud_color_tierra);
    for (var i = 0; i < array_length(ud_particulas); i++)
    {
        var _p = ud_particulas[i];
        draw_set_alpha(min(1, _p.t / 10));
        draw_rectangle(round(_p.x), round(_p.y), round(_p.x) + 1, round(_p.y) + 1, false);
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// Golpe del click según dónde esté el jugador (lo usa obj_mec_golpe). Contexto: obj_mec_golpe.
function mec_underdog_elegir_golpe(_j)
{
    var _bajo = false;
    with (obj_mecanicas_jugador) _bajo = ud_bajo_tierra || ud_accion == UdAccion.SUBIR;
    var _w = keyboard_check(ord("W"));

    if (_bajo)
    {
        if (_w) return { nombre: "Perforacion", danio: 4, kx: 0, ky: -6, stagger: 30, hitstop: 4, jugador_vsp: undefined, zona: [-30, 30, -130, -30] };
        return { nombre: "Pinchazo", danio: 6, kx: 0, ky: -7, stagger: 25, hitstop: 4, jugador_vsp: undefined, zona: [-30, 30, -90, 0] };
    }
    if (_w && mec_en_suelo(_j)) return { nombre: "Taladro arriba", danio: 3, kx: 0, ky: 0, stagger: 25, hitstop: 3, jugador_vsp: undefined, zona: [-30, 30, -130, -30] };
    return { nombre: "Taladrazo", danio: 9, kx: 6, ky: -1, stagger: 25, hitstop: 5, jugador_vsp: undefined, zona: [-6, 56, -50, -10] };
}

function mec_estilo_nombre(_e)
{
    switch (_e)
    {
        case Estilo.SWORDMASTER: return "Swordmaster";
        case Estilo.UNDERDOG: return "Underdog";
        case Estilo.GUNNER: return "Gunner";
        default: return "Base";
    }
}
