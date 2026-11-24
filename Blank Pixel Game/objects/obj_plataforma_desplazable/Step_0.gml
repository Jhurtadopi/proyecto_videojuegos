// Desplazamiento horizontal
x += velocidad_plataforma * direccion_plataforma;

// Comprobar si llegó al extremo derecho
if (x >= x_fin)
{
    x = x_fin;
    direccion_plataforma = -1;
}

// Comprobar si llegó al extremo izquierdo
if (x <= x_inicio)
{
    x = x_inicio;
    direccion_plataforma = 1;
}