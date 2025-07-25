use <bug.scad>
use <chip.scad>

translate([14, 0, 0])
  alien_base();
translate([-14, 0, 0])
  blip(3);
translate([0, 22, 0])
  command_points(1);
translate([0, -17, 0])
  overwatch();
translate([17, -21, 0])
  guard();