// Puerta blindada con cerradura (hija de obj_puerta: sólida). Se abre al acercarse con una llave
// (gasta una de global.nivel_llaves) y activa su canal, así queda abierta al reaparecer en un checkpoint.
// Código de creación: canal; opcional requiere (canal que debe estar activo para poder usar la llave,
// p. ej. el de la arena final: primero hay que vencer a todos).
canal = 7;
requiere = -1;
abriendo = 0;
t = 0;
image_speed = 0;
