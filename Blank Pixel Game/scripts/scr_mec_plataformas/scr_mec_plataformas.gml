// ==============================
// PLATAFORMAS MÓVILES (propio). Contexto: obj_mecanicas_jugador.
// obj_jugador no sabe que está parado sobre algo que se mueve. Aquí:
//   Begin Step: se anota la plataforma móvil (cualquier hijo de obj_solid que no sea obj_solid, salvo
//               las compuertas) sobre la que está parado el jugador.
//   End Step:   cuando todos ya se movieron, se le suma al jugador lo que se movió la plataforma
//               (x - xprevious, y - yprevious). Mientras, la plataforma vuelve un instante a su posición
//               anterior para que no estorbe (si sube, si no el jugador quedaría metido en ella).
// Sirve para las grúas/ascensor y para obj_plataforma_desplazable (sin tocar su código).
// ==============================

function mec_plataformas_crear()
{
    plataforma_bajo = noone;
}

function mec_plataformas_inicio()
{
    plataforma_bajo = noone;
    var _j = jugador;
    var _lista = ds_list_create();
    var _n = 0;
    with (_j) _n = instance_place_list(x, y + 2, obj_solid, _lista, false);
    for (var i = 0; i < _n; i++)
    {
        var _p = _lista[| i];
        if (_p.object_index != obj_solid && _p.object_index != obj_puerta && !object_is_ancestor(_p.object_index, obj_puerta) && _j.bbox_bottom <= _p.bbox_top + 2)
        {
            plataforma_bajo = _p;
            break;
        }
    }
    ds_list_destroy(_lista);
}

function mec_plataformas_fin()
{
    var _p = plataforma_bajo;
    var _j = jugador;
    if (_p == noone || !instance_exists(_p) || !instance_exists(_j)) return;
    var _dx = _p.x - _p.xprevious;
    var _dy = _p.y - _p.yprevious;
    if (_dx == 0 && _dy == 0) return;
    if (_j.vsp < -1) return;                    // saltó: ya no viaja con ella

    var _px = _p.x, _py = _p.y;
    _p.x = _p.xprevious;
    _p.y = _p.yprevious;
    mec_mover_con_choque(_j, _dx, _dy);
    _p.x = _px;
    _p.y = _py;

    // Redondeos: si quedó metido en la plataforma, se sube encima
    var _k = 0;
    while (_k < 8 && instance_exists(_p))
    {
        var _dentro = false;
        with (_j) _dentro = place_meeting(x, y, _p);
        if (!_dentro) break;
        _j.y -= 1;
        _k++;
    }
    if (_dy > 0) _j.vsp = max(_j.vsp, 0);
}
