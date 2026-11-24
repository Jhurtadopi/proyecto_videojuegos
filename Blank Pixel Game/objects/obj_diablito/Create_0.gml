event_inherited();
// Diablito invocado por el jefe: poca vida, rápido, zarpazo débil. Al morir puede soltar un corazón (40 %).
// Usa la caminata/persecución del enemigo base y un ataque propio (obj_golpe_demonio: no daña al jefe).
vida_maxima = 14;
vida = vida_maxima;
vel_caminar = 1.8;
rango_deteccion = 520;
persecucion_duracion = 90;
evitar_bordes = true;
impacto_estampar = 8;
estilo_favorecido = "";
spr_base = sprite_index;
spr = { idle: dem_spr("diablito_idle"), correr: dem_spr("diablito_correr"),
        ataque: dem_spr("diablito_ataque"), aire: dem_spr("diablito_aire") };
atk_t = 0;
atk_cd = 40;
conecto = false;
sin_premio = false;
prev_x = x;
