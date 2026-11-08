// ==============================
// GOLPE / PARRY A PROYECTILES
// Golpear (click izquierdo) en el momento justo devuelve el proyectil al enemigo
// más cercano que esté delante (no necesariamente el que lo disparó).
// ==============================

function mec_parry_crear()
{
    parry_duracion = 18;            // frames totales del golpe
    parry_ventana = 8;              // primeros frames en los que refleja
    parry_alcance = 40;             // px por delante del centro del jugador
    parry_mult_danio = 2;           // el proyectil devuelto hace más daño
    parry_mult_velocidad = 1.5;
    parry_hitstop = 8;

    parry_timer = 0;
    parry_exito_timer = 0;          // para mostrar "PARRY!"
}

function mec_parry_golpeando()
{
    return parry_timer > 0;
}

function mec_parry_en_ventana()
{
    return parry_timer > 0 && (parry_duracion - parry_timer < parry_ventana);
}

// Zona del golpe: [x1, y1, x2, y2]
function mec_parry_zona()
{
    var _j = jugador;
    var _x1 = (mirando == 1) ? _j.x - 8 : _j.x - parry_alcance;
    var _x2 = (mirando == 1) ? _j.x + parry_alcance : _j.x + 8;
    return [_x1, _j.y - _j.sprite_height, _x2, _j.y];
}

// Begin Step
function mec_parry_inicio()
{
    parry_exito_timer = max(0, parry_exito_timer - 1);

    if (parry_timer == 0 && !mec_dash_activo() && !mec_gancho_activo() && mouse_check_button_pressed(mb_left))
    {
        parry_timer = parry_duracion;
    }
}

// End Step
function mec_parry_fin()
{
    if (parry_timer <= 0) return;

    if (mec_parry_en_ventana()) mec_parry_intentar();

    parry_timer--;
}

function mec_parry_intentar()
{
    var _z = mec_parry_zona();
    var _lista = ds_list_create();
    var _n = collision_rectangle_list(_z[0], _z[1], _z[2], _z[3], obj_proyectil, false, true, _lista, false);
    var _exito = false;

    for (var i = 0; i < _n; i++)
    {
        var _p = _lista[| i];
        if (_p.equipo == "jugador") continue;

        mec_parry_reflejar(_p);
        _exito = true;
    }

    ds_list_destroy(_lista);

    if (_exito)
    {
        parry_exito_timer = 20;
        var _frames = parry_hitstop;
        with (obj_controladores) aplicar_hitstop(_frames);
    }
}

function mec_parry_reflejar(_p)
{
    var _objetivo = mec_enemigo_delante(jugador, mirando);

    var _vel = point_distance(0, 0, _p.vx, _p.vy) * parry_mult_velocidad;
    var _dir = (mirando == 1) ? 0 : 180;

    if (_objetivo != noone)
    {
        _dir = point_direction(_p.x, _p.y, _objetivo.x, _objetivo.y - _objetivo.sprite_height / 2);
    }

    _p.vx = lengthdir_x(_vel, _dir);
    _p.vy = lengthdir_y(_vel, _dir);
    _p.owner = jugador;
    _p.equipo = "jugador";
    _p.damage *= parry_mult_danio;
    _p.reflejado = true;
}
