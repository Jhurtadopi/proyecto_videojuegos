// Se congela durante el hitstop, igual que todo lo demás
if (global.hitstop_timer > 0) exit;

timer++;
if (timer >= duracion)
{
    instance_destroy();
    exit;
}

for (var i = 0; i < array_length(escombros); i++)
{
    var _e = escombros[i];
    _e.vy += 0.5;
    _e.x += _e.vx;
    _e.y += _e.vy;
    if (_e.y > y) { _e.y = y; _e.vx *= 0.5; _e.vy = -_e.vy * 0.3; }    // rebota poco en el suelo
}

for (var i = 0; i < array_length(polvo); i++)
{
    var _p = polvo[i];
    _p.x += _p.vx;
    _p.vx *= 0.92;
    _p.r += 0.35;
}
