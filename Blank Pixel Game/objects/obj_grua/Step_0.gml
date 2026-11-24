t++;
if (!iniciado)
{
    // (en el primer Step: el código de creación ya puso los parámetros)
    iniciado = true;
    if (largo_final < 0) largo_final = largo;
    x0 = x;
    carro_x = x;
    plataforma = instance_create_layer(x, y + largo + plat_alto, layer, obj_plataforma_grua);
}
if (!instance_exists(plataforma)) exit;
if (variable_global_exists("hitstop_timer") && global.hitstop_timer > 0) exit;

// ¿El jugador está parado encima de la plataforma?
var _j = nivel_jugador();
var _encima = false;
if (_j != noone)
{
    var _p = plataforma;
    _encima = (_j.bbox_right > _p.bbox_left && _j.bbox_left < _p.bbox_right && abs(_j.bbox_bottom + 1 - _p.bbox_top) <= 3);
}

var _paso = velocidad / max(abs(recorrido), abs(largo_final - largo), 1);
if (nivel_canal_activo(canal))
{
    if (!volviendo)
    {
        if (progreso < 1)
        {
            if (espera < retraso) espera++;
            else progreso = min(1, progreso + _paso);
        }
        else if (ciclo)
        {
            espera_fin = _encima ? 0 : espera_fin + 1;
            if (espera_fin >= pausa) volviendo = true;
        }
    }
    else
    {
        progreso = max(0, progreso - _paso);
        if (progreso <= 0)
        {
            // De vuelta al inicio: se apaga el canal y el botón se puede pulsar otra vez
            volviendo = false;
            espera = 0;
            espera_fin = 0;
            global.nivel_canales[canal] = false;
        }
    }
}

var _e = progreso * progreso * (3 - 2 * progreso);       // arranca y frena suave
var _nx = x0 + recorrido * _e;
var _ny = y + lerp(largo, largo_final, _e) + plat_alto;
var _dx = _nx - plataforma.x;
var _dy = _ny - plataforma.y;

if (_dx != 0 || _dy != 0)
{
    // (el jugador parado encima viaja con ella gracias a scr_mec_plataformas)
    plataforma.x = _nx;
    plataforma.y = _ny;
    carro_x = _nx;
}
