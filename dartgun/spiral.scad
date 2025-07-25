include <common.scad>

// 'start_radius' is in mm. 'slope' is in mm/turn. 't' is in turns.
function spiral_point(start_radius, slope, t) =
  (start_radius + slope*t) * [cos(t*360), sin(t*360)];
  
module spiral(start_radius, slope, turns, thickness) {
  offset(thickness/2)
    polygon([
      each [for (t = [0:0.01:turns]) spiral_point(start_radius-eps, slope, t)],
      each [for (t = [turns:-0.01:0]) spiral_point(start_radius+eps, slope, t)],
    ]);
}