if (global.hitstop_timer > 0) exit;

flash_timer = max(0, flash_timer - 1);
aturdido_timer = max(0, aturdido_timer - 1);
conexion_underdog_timer = max(0, conexion_underdog_timer - 1);

// --- CAMINATA BASE: PATRULLA IZQ/DER Y BÚSQUEDA POR RANGO ---
var _esta_aturdido = (variable_instance_exists(id, "aturdido_timer") && aturdido_timer > 0)
                  || (variable_instance_exists(id, "tiempo_desestabilizado") && tiempo_desestabilizado > 0);

var _en_suelo = place_meeting(x, y + 1, obj_solid);
var _vel_cam_x = 0;

if (caminar_habilitado && vel_caminar > 0 && estado == EnemyState.NORMAL && !_esta_aturdido && _en_suelo)
{
    var _jugador_cerca = false;
    var _jugador_adelante = false;
    var _dir_objetivo = dir_patrulla;
    var _dir_jugador = 0
    var _vel_cam_x = 0;

    // 1. Comprobar si el jugador está dentro del rango
    if (instance_exists(obj_jugador))
    {
        var _j = instance_nearest(x, y, obj_jugador);
        var _dist = point_distance(x, y, _j.x, _j.y);

        if (_dist <= rango_deteccion && _j.x != x)
        {
            _jugador_cerca = true;
            _dir_jugador = sign(_j.x - x);
            _jugador_adelante = (_dir_jugador == mirando);
        }
    }

    // Actualizar temporizador del ciclo de persecución
    if (_jugador_cerca && _jugador_adelante)
    {
        // Si está mirando hacia el jugador en rango, inicia o renueva el ciclo
        persecucion_timer = persecucion_duracion;
    }
    else if (persecucion_timer > 0)
    {
        // El ciclo sigue corriendo mientras tenga frames restantes
        persecucion_timer--;
    }

    var _en_ciclo_persecucion = (persecucion_timer > 0);

    // 2. Si NO está en ciclo de persecución, patrulla normal de izquierda a derecha
    if (!_en_ciclo_persecucion)
    {
        if (place_meeting(x + dir_patrulla * max(1, vel_caminar), y, obj_solid))
        {
            dir_patrulla = -dir_patrulla;
        }
        else if (evitar_bordes)
        {
            var _hay_suelo = place_meeting(x + dir_patrulla * margen_borde, y + 1, obj_solid);
            if (!_hay_suelo)
            {
                dir_patrulla = -dir_patrulla;
            }
        }

        _dir_objetivo = dir_patrulla;
        mirando = _dir_objetivo;
        _vel_cam_x = _dir_objetivo * vel_caminar;
    }
    else
    {
        // 3. Dentro del ciclo de persecución:
        if (_jugador_cerca && _jugador_adelante)
        {
            // El jugador está delante: persigue en la dirección en la que mira
            _dir_objetivo = mirando;
            var _hay_suelo_pers = !evitar_bordes || place_meeting(x + _dir_objetivo * margen_borde, y + 1, obj_solid);

            _vel_cam_x = _hay_suelo_pers ? (_dir_objetivo * vel_caminar) : 0;
        }
        else
        {
            // Durante el ciclo el jugador está detrás (o fuera de rango): no hace nada
            _vel_cam_x = 0;

            // Si en algún momento quieres que se dé la vuelta cuando el jugador esté detrás,
            // descomenta esta línea:
            if (_jugador_cerca && !_jugador_adelante) { mirando = _dir_jugador; }
        }
    }

    // Aplicar movimiento horizontal de caminata (respetando tu física de hsp)
    var _vx_total = hsp + _vel_cam_x;
    if (place_meeting(x + _vx_total, y, obj_solid))
    {
        while (!place_meeting(x + sign(_vx_total), y, obj_solid)) x += sign(_vx_total);
        hsp = 0;
        _vx_total = 0;
    }
    x += _vx_total;
}

// Movimiento horizontal total (empuje por golpe + caminata)
var _vx_total = hsp + _vel_cam_x;

if (place_meeting(x + _vx_total, y, obj_solid))
{
    while (!place_meeting(x + sign(_vx_total), y, obj_solid)) x += sign(_vx_total);
    hsp = 0;
    _vx_total = 0;
}

x += _vx_total;

if (lanzable)
{
    if (estado == EnemyState.KNOCKED_DOWN)
    {
        derribado_timer--;
        if (derribado_timer <= 0) estado = EnemyState.NORMAL;
    }

    vsp = min(vsp + gravedad_enemigo, vsp_max);

    if (place_meeting(x + hsp, y, obj_solid))
    {
        while (!place_meeting(x + sign(hsp), y, obj_solid)) x += sign(hsp);
        hsp = 0;
    }

    x += hsp;

    if (place_meeting(x, y + vsp, obj_solid))
    {
        while (!place_meeting(x, y + sign(vsp), obj_solid)) y += sign(vsp);

        if (vsp > 0)
        {
            juggle_cuenta = 0;      // tocó el suelo: el juggle vuelve a empezar

            if (estampado)
            {
                estampado = false;
                aplicar_danio(danio_estampado);
                if (vida <= 0) exit;

                estado = EnemyState.KNOCKED_DOWN;
                derribado_timer = derribado_frames;
                conexion_underdog_timer = conexion_underdog_frames;   // ventana para el Underdog
            }
            else if (estado == EnemyState.AIRBORNE)
            {
                estado = EnemyState.NORMAL;
            }
        }

        vsp = 0;
    }

    y += vsp;

    if (place_meeting(x, y + 1, obj_solid))
    {
        hsp *= friccion_suelo;
        if (abs(hsp) < 0.1) hsp = 0;
    }
}

if (instance_exists(hurtbox))
{
    hurtbox.x = x;
    hurtbox.y = y;
}
