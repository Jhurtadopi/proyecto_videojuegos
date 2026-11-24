t++;
var _cerrar = nivel_canal_activo(canal_cierre) && !nivel_canal_activo(canal_abrir);
if (_cerrar)
{
    if (p == 0) with (obj_camara) aplicar_temblor(6, 18);
    p = min(1, p + 1 / 8);
    y = y0;
}
else
{
    p = max(0, p - 1 / 30);
    y = (p > 0) ? y0 : y0 + 100000;
}
