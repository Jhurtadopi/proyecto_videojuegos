t++;
if (nivel_canal_activo(canal))
{
    if (abriendo == 0) with (obj_camara) aplicar_temblor(4, 20);
    abriendo = min(1, abriendo + 1 / 40);
    y -= 2;
    if (abriendo >= 1) instance_destroy();
}
