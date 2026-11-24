// Compuerta que empieza ABIERTA y cae de golpe al activarse canal_cierre (la activa una obj_arena cuando
// entra el jugador). Se vuelve a abrir con canal_abrir. Abierta se aparta fuera de la room (sin colisión).
// Código de creación: canal_cierre, canal_abrir.
canal_cierre = 6;
canal_abrir = 5;
canal = -1;
x0 = x;
y0 = y;
p = 0;              // 0 abierta .. 1 cerrada
t = 0;
image_speed = 0;
y = y0 + 100000;
