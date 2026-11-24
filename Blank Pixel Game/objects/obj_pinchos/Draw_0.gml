var _n = max(1, round(image_xscale));
var _x0 = x - _n * 16;
for (var i = 0; i < _n; i++) draw_sprite(sprite_index, 0, _x0 + 16 + i * 32, y);
