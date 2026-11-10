// ==============================
// ESTILO SWORDMASTER
// Espada a corta distancia con alto control en el aire: lanza enemigos, los mantiene
// arriba con cortes aéreos y los estampa contra el suelo.
// Las funciones corren en el contexto de obj_mec_golpe. El dash de este estilo es el
// dash base. Cada corte usa el click del golpe, así que también hace parry.
// ==============================

function mec_swordmaster_crear()
{
    sm_lanzar_vel = -13;    // velocidad del lanzamiento; enemigo y jugador usan la misma para subir juntos
    sm_aire_vel = -2;       // velocidad vertical al conectar un corte aéreo (enemigo y jugador)
    sm_estampar_vel = 16;   // velocidad hacia abajo del enemigo estampado
    sm_picado_vel = 12;     // velocidad de caída del jugador al estampar (obj_jugador la limita a 12)

    sm_picado = false;      // el jugador está cayendo tras una estampada

    // kx se multiplica por la dirección en que mira el jugador.
    // jugador_vsp se aplica al jugador solo si el golpe conecta (undefined = no lo mueve).
    sm_corte = { nombre: "Corte", danio: 10, kx: 3, ky: 0, stagger: 10, hitstop: 5, jugador_vsp: undefined };
    sm_lanzador = { nombre: "Lanzador", danio: 8, kx: 0, ky: sm_lanzar_vel, stagger: 20, hitstop: 7, jugador_vsp: sm_lanzar_vel };
    sm_aereo = { nombre: "Corte aereo", danio: 6, kx: 1, ky: sm_aire_vel, stagger: 10, hitstop: 4, jugador_vsp: sm_aire_vel };
    sm_estampada = { nombre: "Estampada", danio: 12, kx: 0, ky: sm_estampar_vel, stagger: 30, hitstop: 8, jugador_vsp: undefined };
}

// Elige el corte según el input en el momento de golpear
function mec_swordmaster_elegir_golpe(_j)
{
    if (mec_en_suelo(_j))
    {
        return keyboard_check(ord("W")) ? sm_lanzador : sm_corte;
    }

    if (keyboard_check(ord("S")))
    {
        sm_picado = true;       // el jugador cae con el enemigo, conecte o no
        return sm_estampada;
    }

    return sm_aereo;
}

// Mantiene la caída de la estampada hasta aterrizar o usar el dash o el gancho
function mec_swordmaster_paso(_j)
{
    if (!sm_picado) return;

    var _cancelar = !instance_exists(_j) || mec_en_suelo(_j);

    with (obj_mecanicas_jugador)
    {
        if (mec_dash_activo() || mec_gancho_activo()) _cancelar = true;
    }

    if (_cancelar) sm_picado = false;
    else _j.vsp = sm_picado_vel;
}
