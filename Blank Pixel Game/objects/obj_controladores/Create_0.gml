global.hitstop_timer = 0;

aplicar_hitstop = function(_frames)
{
    global.hitstop_timer = max(
        global.hitstop_timer,
        _frames
    );
};
