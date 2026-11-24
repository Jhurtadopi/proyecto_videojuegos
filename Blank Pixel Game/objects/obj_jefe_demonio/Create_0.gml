event_inherited();
// JEFE: AZRAEK, EL DESOLLADOR. Del tamaño del jugador, rápido y escurridizo, con combos en el suelo y en
// el aire (lanza al jugador y lo sigue), 2 fases e invocación de diablitos que sueltan corazones.
// Hijo de obj_enemigo: recibe los golpes del jugador como cualquier enemigo. Código de creación: siguiente.
nombre_jefe = "AZRAEK, EL DESOLLADOR";
siguiente = -1;                 // room a la que lleva el portal al vencerlo (-1 = la siguiente del orden)

vida_maxima = 240;
vida = vida_maxima;
vel_caminar = 0;                // se mueve con su propia IA
caminar_habilitado = false;
evitar_bordes = false;
lanzable = true;
impacto_estampar = 12;
danio_estampado = 6;
estilo_favorecido = "";

spr_base = sprite_index;
spr = {
    idle: dem_spr("demonio_idle"), correr: dem_spr("demonio_correr"), tajo: dem_spr("demonio_tajo"),
    lanzador: dem_spr("demonio_lanzador"), aire: dem_spr("demonio_aire"), picada: dem_spr("demonio_picada"),
    invocar: dem_spr("demonio_invocar"), aturdido: dem_spr("demonio_aturdido"), esquiva: dem_spr("demonio_esquiva"),
};

fase = 1;
ia = "intro";
ia_t = 0;
sub = 0;
t = 0;
invulnerable = 0;
golpes_racha = 0;               // golpes recibidos seguidos: al pasar el límite rompe el combo (escape)
racha_timer = 0;
escapar = false;
cooldown = 60;
t_invocar = 240;
diablitos_max = 3;
conecto = false;
aire_golpes = 0;
dir_escape = 1;
alpha = 1;
aura = 0;
estela = [];
portales = [];
prev_x = x;
inicio_y = y;
mirando = -1;

// Daño recibido: sin daño durante la invulnerabilidad; cuenta la racha para escapar
recibir_base = recibir_impacto;
recibir_impacto = function(_d, _kx, _ky, _st)
{
    if (invulnerable > 0 || ia == "intro" || ia == "transicion") return;
    recibir_base(_d, _kx, _ky, _st * 0.6);
    if (vida <= 0) return;
    golpes_racha++;
    racha_timer = 45;
    if (golpes_racha >= ((fase == 1) ? 6 : 4)) escapar = true;
};
