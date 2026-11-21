// ==============================
// BUFFER DEL GOLPE
// Un click durante la recuperación del golpe anterior se guarda y el golpe sale apenas
// termina (para encadenar el combo del Swordmaster sin clavar el timing).
// No modifica scr_mec_parry: solo arranca parry_timer igual que lo haría mec_parry_inicio.
// Begin Step, ANTES de mec_parry_inicio. Contexto: obj_mecanicas_jugador.
// ==============================

function mec_buffer_crear()
{
    golpe_buffer_max = 8;       // frames que se recuerda un click hecho antes de tiempo
    golpe_buffer = 0;
}

function mec_buffer_inicio()
{
    if (mouse_check_button_pressed(mb_left))
    {
        if (parry_timer > 0) golpe_buffer = golpe_buffer_max;   // libre: lo maneja mec_parry_inicio
    }
    else
    {
        golpe_buffer = max(0, golpe_buffer - 1);
    }

    if (golpe_buffer > 0 && parry_timer == 0 && !mec_dash_activo() && !mec_gancho_activo())
    {
        parry_timer = parry_duracion;
        golpe_buffer = 0;
    }
}
