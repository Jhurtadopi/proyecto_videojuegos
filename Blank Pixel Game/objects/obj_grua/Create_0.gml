// Grúa: un carro en un riel del techo con una plataforma colgando (sólida: se puede pisar
// y engancharle el gancho). Al activarse su canal lleva la plataforma a su destino y se queda ahí.
// La instancia se coloca en el inicio del riel. Código de creación:
//   canal, recorrido (px en X, negativo = izquierda), largo (cable inicial), largo_final
//   (cable al final; -1 = igual), velocidad (px/frame), retraso (frames antes de arrancar),
//   ciclo (true = ascensor: al llegar espera "pausa" frames sin nadie encima, vuelve y su botón
//   se puede volver a pulsar; así nunca queda inalcanzable).
canal = 1;
recorrido = 320;
largo = 192;
largo_final = -1;
velocidad = 2;
retraso = 0;
ciclo = false;
pausa = 90;

iniciado = false;
volviendo = false;
espera_fin = 0;
plataforma = noone;
progreso = 0;
espera = 0;
t = 0;
x0 = x;
carro_x = x;
plat_alto = sprite_get_height(spr_nivel_plataforma);
