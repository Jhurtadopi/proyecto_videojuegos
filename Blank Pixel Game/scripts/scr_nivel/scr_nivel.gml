// ==============================
// ELEMENTOS DE NIVEL (propios): canales, checkpoints y reaparición.
// Un botón activa un canal (número). Las grúas y compuertas con ese canal reaccionan.
// El canal y los demás parámetros de cada instancia se ponen en su código de creación
// (lo escribe arte_generado/generar_niveles.py).
// ==============================

function nivel_canal_activo(_c)
{
    if (!variable_global_exists("nivel_canales")) return false;
    return _c >= 0 && _c < array_length(global.nivel_canales) && global.nivel_canales[_c];
}

function nivel_activar_canal(_c)
{
    if (!variable_global_exists("nivel_canales")) global.nivel_canales = [];
    while (array_length(global.nivel_canales) <= _c) array_push(global.nivel_canales, false);
    global.nivel_canales[_c] = true;
}

function nivel_jugador()
{
    return instance_exists(obj_jugador) ? instance_find(obj_jugador, 0) : noone;
}

function nivel_invulnerable()
{
    return variable_global_exists("nivel_invulnerable") && global.nivel_invulnerable > 0;
}

// Punto de reaparición: el último checkpoint de esta room o, si no hay, el inicio del nivel
function nivel_punto_reaparicion()
{
    if (variable_global_exists("nivel_cp") && is_struct(global.nivel_cp) && global.nivel_cp.room == room)
        return [global.nivel_cp.x, global.nivel_cp.y];
    var _r = undefined;
    with (obj_nivel) _r = [inicio_x, inicio_y];
    return _r;
}

// Lleva al jugador a (_x, _y) cancelando lo que estuviera haciendo (gancho, excavación...)
function nivel_mover_jugador(_x, _y)
{
    var _j = nivel_jugador();
    if (_j == noone) return;
    with (obj_mecanicas_jugador)
    {
        if (mec_gancho_activo()) mec_gancho_soltar();
        gancho_inercia_x = 0;
        if (ud_bajo_tierra) mec_underdog_salir(false);
        if (ud_accion != UdAccion.ARRASTRE) ud_accion = UdAccion.NINGUNA;
        dash_timer = 0;
        x_inicio = _x;
        y_inicio = _y;
    }
    _j.x = _x;
    _j.y = _y;
    _j.hsp = 0;
    _j.vsp = 0;
    with (obj_camara) saltar_a(_x, _y);
}

// Caída al vacío o pinchos: vuelve al punto de reaparición con daño e invulnerabilidad breve
function nivel_reaparecer(_danio)
{
    var _p = nivel_punto_reaparicion();
    var _j = nivel_jugador();
    if (_j == noone || is_undefined(_p)) return;
    global.nivel_invulnerable = 60;
    global.nivel_flash = 14;
    nivel_mover_jugador(_p[0], _p[1]);
    if (_danio > 0 && instance_exists(_j)) _j.recibir_impacto(_danio, 0, 0, 0);
}

// Texto pequeño con contorno (avisos de los elementos de nivel)
function nivel_texto(_x, _y, _txt, _col, _alpha)
{
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_alpha(_alpha);
    draw_set_color(c_black);
    draw_text(_x + 1, _y + 1, _txt);
    draw_set_color(_col);
    draw_text(_x, _y, _txt);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
