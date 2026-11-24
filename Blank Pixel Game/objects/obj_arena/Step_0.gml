aviso = max(0, aviso - 1);
if (abierta) exit;
if (nivel_canal_activo(canal)) { abierta = true; exit; }          // ya abierta (canal recuperado de un checkpoint)
var _x1 = x, _y1 = y, _x2 = x + ancho, _y2 = y + alto;
var _n = 0;
var _mj = noone, _mv = -1;
with (obj_enemigo) if (x >= _x1 && x <= _x2 && y >= _y1 && y <= _y2 + 40)
{
    _n++;
    if (vida_maxima > _mv) { _mv = vida_maxima; _mj = id; }
}
if (jefe_nombre != "")
{
    if (!instance_exists(jefe)) jefe = _mj;
    if (instance_exists(jefe))
    {
        if (!activa) jefe.caminar_habilitado = false;     // espera en su sala hasta que entre el jugador
        premio_x = jefe.x;
        premio_y = jefe.y;
        if (!(jefe.x >= _x1 && jefe.x <= _x2)) _n++;      // cuenta aunque se haya salido de la zona
    }
}
restantes = _n;
var _j = nivel_jugador();
if (!activa && _j != noone && point_in_rectangle(_j.x, _j.y - 32, _x1, _y1, _x2, _y2))
{
    activa = true;
    with (obj_camara) aplicar_temblor(4, 20);
    if (canal_cierre >= 0) nivel_activar_canal(canal_cierre);
    if (instance_exists(jefe)) jefe.caminar_habilitado = true;
}
if (activa && _n == 0)
{
    abierta = true;
    aviso = 150;
    nivel_activar_canal(canal);
    if (premio != noone)
    {
        if (premio_x == 0) { premio_x = x + ancho / 2; premio_y = y + alto; }
        instance_create_layer(premio_x, premio_y - 40, "Instances", premio);
    }
    with (obj_camara) aplicar_temblor(6, 30);
}
