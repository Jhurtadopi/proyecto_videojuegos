// Checkpoint: al tocarlo guarda el punto de reaparición (solo si está más adelante que el
// actual) y cura 30 de vida. Sobrevive a R / morir (global.nivel_cp) mientras sigas en la room.
// Código de creación: orden (posición en el recorrido; los niveles no siempre avanzan a la derecha).
// Guarda también los canales activos, para que las compuertas abiertas sigan abiertas al reaparecer.
orden = x;
activo = false;
revisado = false;
anim = 0;
t = 0;
image_speed = 0;
