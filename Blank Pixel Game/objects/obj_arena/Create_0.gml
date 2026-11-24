// Arena: zona (ancho x alto px desde su esquina superior izquierda). Cuando el jugador entra se activa y,
// cuando ya no queda ningún enemigo dentro, activa su canal (abre la compuerta de la salida).
// Código de creación: ancho, alto, canal; opcionales: mensaje, jefe_nombre (muestra la barra de vida del
// enemigo con más vida máxima de la zona, p. ej. un minijefe).
// canal_cierre: canal que se activa al entrar (cierra las obj_puerta_cierre: no se puede salir).
// premio: objeto que aparece donde murió el jefe al vencer a todos (p. ej. obj_llave).
mensaje = "Acaba con todos para abrir la salida";
jefe_nombre = "";
jefe = noone;
canal_cierre = -1;
premio = noone;
premio_x = 0;
premio_y = 0;
ancho = 320;
alto = 320;
canal = 1;
activa = false;
abierta = false;
restantes = 0;
aviso = 0;
