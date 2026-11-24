if (variable_global_exists("hitstop_timer") && global.hitstop_timer > 0) exit;
if (!instance_exists(dueno)) { instance_destroy(); exit; }
dem_golpe_colocar();
frames--;
if (frames <= 0) instance_destroy();
