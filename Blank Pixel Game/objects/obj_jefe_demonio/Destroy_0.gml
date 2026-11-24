// Vencido: explosión, los diablitos desaparecen (sin corazón) y aparece el portal de salida
with (obj_diablito) { sin_premio = true; instance_destroy(); }
with (obj_golpe_demonio) instance_destroy();
instance_create_layer(x, y, layer, obj_fx_estampada, { fuerza: 1.4, radio: 140 });
with (obj_camara) aplicar_temblor(12, 40);
var _m = instance_create_layer(room_width / 2, inicio_y, layer, obj_meta);
_m.siguiente = siguiente;
