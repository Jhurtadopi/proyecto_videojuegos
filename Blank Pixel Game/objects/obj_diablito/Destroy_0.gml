// 40 % de probabilidad de soltar un corazón
if (vida <= 0 && !sin_premio && random(1) < 0.4) instance_create_layer(x, y - 20, layer, obj_corazon);
