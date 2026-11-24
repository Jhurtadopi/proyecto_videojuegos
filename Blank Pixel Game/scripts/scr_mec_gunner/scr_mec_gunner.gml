// ==============================
// ESTILO GUNNER (pistolero a distancia). Contexto: obj_mecanicas_jugador.
// El jugador dispara hacia el cursor del mouse en vez de pelear cuerpo a cuerpo. Tiene tres armas
// y la habilidad del estilo (tecla E) es cambiar entre ellas. No modifica obj_jugador ni
// obj_enemigo: solo escribe variables en tiempo de ejecucion y crea instancias (obj_proyectil,
// equipo "jugador").
//
//   Click izquierdo -> disparar hacia el cursor (cadencia y municion por arma)
//   E               -> cambiar de arma (pistola -> escopeta -> franco)
//   R               -> recargar el arma actual
//
// ARMAS:
//   Pistola  : cargador 9, bala recta rapida, recarga automatica al vaciarse.
//   Escopeta : cargador 2, abanico de perdigones, recarga automatica al vaciarse.
//   Franco   : cargador 5, super bala blindada grande/rapida que atraviesa; cada bala se regenera
//              sola con el tiempo (como un ultimate), no recarga de golpe.
//
// El disparo reemplaza al golpe cuerpo a cuerpo (obj_mec_golpe lo desactiva en este estilo).
// ==============================

enum GnArma
{
    PISTOLA,
    ESCOPETA,
    FRANCO
}

function mec_gunner_crear()
{
    // Definicion de cada arma. "cargador" = balas maximas; "auto_recarga" = frames para
    // recargar el cargador entero al vaciarse (0 = no se recarga sola de golpe);
    // "regen" = frames para regenerar UNA bala (0 = no regenera sola, como la ulti del franco).
    gn_armas = [
        {
            nombre: "Pistola",
            cargador: 9,
            cadencia: 10,           // frames entre disparos
            perdigones: 1,
            dispersion: 0,          // grados de abanico (escopeta)
            vel: 15,
            danio: 12,
            stagger: 12,
            vida: 90,
            tam: 1.0,               // escala visual / de la bala
            atraviesa: false,
            color: make_color_rgb(0, 230, 255),
            recarga_auto: 70,       // recarga sola el cargador al quedar en 0
            recarga_manual: 45,     // frames de la recarga con R
            regen: 0,
            bala_spr: asset_get_index("spr_gn_bala_pistola"),
            hud_spr: asset_get_index("spr_gn_hud_pistola"),
            arma_spr: -1            // la pistola usa el brazo del personaje
        },
        {
            nombre: "Escopeta",
            cargador: 2,
            cadencia: 28,
            perdigones: 6,
            dispersion: 34,
            vel: 13,
            danio: 7,               // por perdigon
            stagger: 8,
            vida: 26,               // alcance corto
            tam: 0.8,
            atraviesa: false,
            color: make_color_rgb(255, 170, 40),
            recarga_auto: 95,
            recarga_manual: 70,
            regen: 0,
            bala_spr: asset_get_index("spr_gn_bala_escopeta"),
            hud_spr: asset_get_index("spr_gn_hud_escopeta"),
            arma_spr: asset_get_index("spr_gn_arma_escopeta")
        },
        {
            nombre: "Franco",
            cargador: 5,
            cadencia: 34,
            perdigones: 1,
            dispersion: 0,
            vel: 26,
            danio: 55,
            stagger: 60,
            vida: 160,
            tam: 2.2,               // bala grande y blindada
            atraviesa: true,        // super bala: traspasa enemigos
            color: make_color_rgb(255, 60, 90),
            recarga_auto: 0,        // no recarga de golpe
            recarga_manual: 0,
            regen: 150,             // regenera una bala cada 150 frames (como ulti)
            bala_spr: asset_get_index("spr_gn_bala_franco"),
            hud_spr: asset_get_index("spr_gn_hud_franco"),
            arma_spr: asset_get_index("spr_gn_arma_franco")
        }
    ];

    gn_arma = GnArma.PISTOLA;

    // Municion actual por arma (empieza llena). Se conserva al cambiar de arma.
    gn_municion = [];
    for (var i = 0; i < array_length(gn_armas); i++) array_push(gn_municion, gn_armas[i].cargador);

    gn_cadencia = 0;                // frames restantes hasta poder disparar
    gn_recarga_timer = 0;           // > 0 mientras recarga (auto o manual)
    gn_regen_timer = 0;             // cuenta para regenerar una bala del franco
    gn_cambio_flash = 0;            // destello al cambiar de arma

    // Animacion / efectos
    gn_disparo_anim = 0;
    gn_disparo_anim_max = 8;
    gn_disparo_dir = 0;             // ultima direccion de disparo (grados)
    gn_fogonazo = 0;

    // Posicion del canon respecto a los pies del jugador
    gn_canon_dx = 20;               // hacia donde apunta
    gn_canon_dy = -40;              // altura del brazo

    gn_retroceso = 0;               // empuje horizontal breve al disparar
}

function mec_gunner_activo()
{
    return global.estilo == Estilo.GUNNER;
}

function mec_gunner_arma()
{
    return gn_armas[gn_arma];
}

// Direccion hacia el cursor del mouse desde el canon (grados)
function mec_gunner_direccion(_j)
{
    var _c = mec_gunner_canon(_j);
    return point_direction(_c[0], _c[1], mouse_x, mouse_y);
}

// Lado hacia donde apunta el jugador (segun el mouse): 1 derecha, -1 izquierda
function mec_gunner_lado_apuntado(_j)
{
    return (mouse_x >= _j.x) ? 1 : -1;
}

// Punto del canon/hombro en el mundo. Se coloca del lado del mouse (apuntado), no del cuerpo.
function mec_gunner_canon(_j)
{
    var _lado = mec_gunner_lado_apuntado(_j);
    return [_j.x + gn_canon_dx * _lado, _j.y + gn_canon_dy];
}

// Boca del arma: punta del sprite del arma apuntando al cursor (o el canon si es la pistola)
function mec_gunner_boca(_j)
{
    var _a = mec_gunner_arma();
    var _c = mec_gunner_canon(_j);
    if (_a.arma_spr == -1) return _c;
    var _dir = mec_gunner_direccion(_j);
    var _largo = sprite_get_width(_a.arma_spr) * 0.5;
    return [_c[0] + lengthdir_x(_largo, _dir), _c[1] + lengthdir_y(_largo, _dir)];
}

function mec_gunner_disparar(_j)
{
    var _a = mec_gunner_arma();
    var _dir = mec_gunner_direccion(_j);
    var _c = mec_gunner_boca(_j);           // las balas salen de la boca del arma

    // Perdigones repartidos en el abanico de dispersion
    var _n = _a.perdigones;
    for (var i = 0; i < _n; i++)
    {
        var _off = (_n > 1) ? lerp(-_a.dispersion / 2, _a.dispersion / 2, i / (_n - 1)) : 0;
        _off += random_range(-2, 2);        // pequeña variacion natural
        var _d = _dir + _off;

        var _p = instance_create_layer(_c[0], _c[1], "Instances", obj_proyectil);
        _p.owner = _j;
        _p.equipo = "jugador";
        _p.vx = lengthdir_x(_a.vel, _d);
        _p.vy = lengthdir_y(_a.vel, _d);
        _p.damage = _a.danio;
        _p.knockback_y = -2;
        _p.stagger = _a.stagger;
        _p.vida_frames = _a.vida;
        _p.image_blend = _a.color;
        // Variables propias del Gunner (seguras de añadir desde fuera)
        _p.gn_bala = true;
        _p.gn_tam = _a.tam;
        _p.gn_color = _a.color;
        _p.gn_atraviesa = _a.atraviesa;

        // Sprite de la bala segun el arma, orientado hacia donde viaja
        if (_a.bala_spr != -1)
        {
            _p.sprite_index = _a.bala_spr;
            _p.mask_index = _a.bala_spr;        // el hitbox sigue al sprite de la bala
            _p.image_angle = _d;
            _p.image_blend = c_white;           // el sprite ya tiene color propio
        }
    }

    gn_municion[gn_arma] = max(0, gn_municion[gn_arma] - 1);

    gn_cadencia = _a.cadencia;
    gn_disparo_anim = gn_disparo_anim_max;
    gn_disparo_dir = _dir;
    gn_fogonazo = 5;
    // Retroceso en sentido contrario al disparo (horizontal), segun hacia donde apunta el mouse
    gn_retroceso = -lengthdir_x(1 + _a.tam, _dir);

    var _fuerza = 1 + _a.tam;
    with (obj_camara) aplicar_temblor(_fuerza, 4 + floor(_a.tam * 2));
}

function mec_gunner_cambiar_arma()
{
    gn_arma = (gn_arma + 1) mod array_length(gn_armas);
    gn_cambio_flash = 12;
    gn_recarga_timer = 0;           // cambiar de arma cancela una recarga en curso
    with (obj_camara) aplicar_temblor(1, 3);
}

function mec_gunner_recargar()
{
    var _a = mec_gunner_arma();
    if (_a.recarga_manual <= 0) return;                 // el franco no recarga de golpe
    if (gn_municion[gn_arma] >= _a.cargador) return;    // ya esta llena
    if (gn_recarga_timer > 0) return;                   // ya recargando
    gn_recarga_timer = _a.recarga_manual;
}

// Begin Step
function mec_gunner_inicio()
{
    gn_cadencia = max(0, gn_cadencia - 1);
    gn_disparo_anim = max(0, gn_disparo_anim - 1);
    gn_fogonazo = max(0, gn_fogonazo - 1);
    gn_cambio_flash = max(0, gn_cambio_flash - 1);

    if (!mec_gunner_activo()) return;

    var _j = jugador;
    var _a = mec_gunner_arma();

    // El cuerpo mira segun A/D (lo fija Step_1 antes de las mecánicas). Las armas apuntan al
    // mouse de forma independiente. Excepcion: si estas QUIETO y disparas, el cuerpo encara el
    // lado del disparo.
    var _moviendo = keyboard_check(ord("A")) || keyboard_check(ord("D"));
    if (!_moviendo && !mec_dash_activo() && mouse_check_button(mb_left))
    {
        mirando = mec_gunner_lado_apuntado(_j);
    }

    // Cambiar de arma (habilidad del estilo)
    if (keyboard_check_pressed(ord("E"))) mec_gunner_cambiar_arma();

    // Recargar manualmente
    if (keyboard_check_pressed(ord("R"))) mec_gunner_recargar();

    // Regeneracion del franco tipo ultimate: se rellena solo con el tiempo, aunque tengas
    // equipada otra arma. Una bala cada "regen" frames hasta el cargador.
    var _i_franco = GnArma.FRANCO;
    var _franco = gn_armas[_i_franco];
    if (_franco.regen > 0 && gn_municion[_i_franco] < _franco.cargador)
    {
        gn_regen_timer++;
        if (gn_regen_timer >= _franco.regen)
        {
            gn_regen_timer = 0;
            gn_municion[_i_franco] = min(_franco.cargador, gn_municion[_i_franco] + 1);
        }
    }
    else gn_regen_timer = 0;

    // Recarga en curso (auto o manual): al terminar, llena el cargador
    if (gn_recarga_timer > 0)
    {
        gn_recarga_timer--;
        if (gn_recarga_timer <= 0) gn_municion[gn_arma] = _a.cargador;
        return;     // no dispara mientras recarga
    }

    // Recarga automatica al quedar sin balas (solo armas con recarga_auto)
    if (gn_municion[gn_arma] <= 0 && _a.recarga_auto > 0)
    {
        gn_recarga_timer = _a.recarga_auto;
        return;
    }

    // No dispara mientras usa otra accion que ocupa el cuerpo
    var _libre = !mec_dash_activo() && !mec_gancho_activo() && !mec_gancho_enemigo_activo();

    if (_libre && mouse_check_button(mb_left) && gn_cadencia == 0 && gn_municion[gn_arma] > 0)
    {
        mec_gunner_disparar(_j);
    }
}

// End Step
function mec_gunner_fin()
{
    var _j = jugador;
    if (!instance_exists(_j)) return;
    if (!mec_gunner_activo()) return;

    // Retroceso del disparo: empuje corto que se desvanece
    if (gn_retroceso != 0)
    {
        _j.x += gn_retroceso;
        gn_retroceso *= 0.6;
        if (abs(gn_retroceso) < 0.2) gn_retroceso = 0;
    }
}

// ¿Esta recargando ahora mismo? (para el HUD)
function mec_gunner_recargando()
{
    return gn_recarga_timer > 0;
}

// Draw de obj_mecanicas_jugador: arma en la mano, fogonazo, retícula del mouse y estela de balas
function mec_gunner_dibujar()
{
    var _j = jugador;
    if (_j == noone || !instance_exists(_j)) return;
    if (!mec_gunner_activo()) return;

    var _a = mec_gunner_arma();
    var _c = mec_gunner_canon(_j);
    var _dir = mec_gunner_direccion(_j);        // hacia el cursor

    // Arma en la mano, apuntando al cursor (la pistola usa el brazo del personaje)
    if (_a.arma_spr != -1)
    {
        // El sprite mira a la derecha; al apuntar a la izquierda se voltea en Y para no quedar boca abajo
        var _yscale = (mec_gunner_lado_apuntado(_j) == 1) ? 1 : -1;
        draw_sprite_ext(_a.arma_spr, 0, _c[0], _c[1], 1, _yscale, _dir, c_white, 1);
    }
    var _punta = mec_gunner_boca(_j);           // boca del arma (o canon si es la pistola)

    // Fogonazo en la boca del arma
    if (gn_fogonazo > 0)
    {
        var _al = gn_fogonazo / 5;
        gpu_set_blendmode(bm_add);
        draw_set_color(_a.color);
        draw_set_alpha(_al);
        var _r = (3 + (5 - gn_fogonazo) * 2) * _a.tam;
        draw_circle(_punta[0], _punta[1], _r, false);
        draw_line_width(_punta[0], _punta[1],
            _punta[0] + lengthdir_x(14 * _a.tam, gn_disparo_dir), _punta[1] + lengthdir_y(14 * _a.tam, gn_disparo_dir), 3);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }

    // Retícula en el cursor, del color del arma
    gpu_set_blendmode(bm_add);
    draw_set_color(_a.color);
    draw_set_alpha(0.9);
    draw_circle(mouse_x, mouse_y, 6, true);
    draw_line(mouse_x - 9, mouse_y, mouse_x - 3, mouse_y);
    draw_line(mouse_x + 3, mouse_y, mouse_x + 9, mouse_y);
    draw_line(mouse_x, mouse_y - 9, mouse_x, mouse_y - 3);
    draw_line(mouse_x, mouse_y + 3, mouse_x, mouse_y + 9);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);

    // Estela de las balas (el sprite de la bala ya lo dibuja obj_proyectil). El franco, mas larga.
    with (obj_proyectil)
    {
        if (!variable_instance_exists(id, "gn_bala") || !gn_bala) continue;
        var _ang = point_direction(0, 0, vx, vy);
        var _largo = point_distance(0, 0, vx, vy) * 0.6 * gn_tam;
        gpu_set_blendmode(bm_add);
        draw_set_color(gn_color);
        draw_set_alpha(0.35);
        draw_line_width(x, y, x - lengthdir_x(_largo, _ang), y - lengthdir_y(_largo, _ang), 3 * gn_tam);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
    }

    draw_set_color(c_white);
}
