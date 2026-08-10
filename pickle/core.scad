use <paddle.scad>

positioning_square();

print_position()
intersection_for(z = [
  // The very first layer is 0.2mm instead of 0.16mm.
  0.2 + 3*0.16,
  -4*0.16
])
translate([0, 0, z]) {
  wedge();
  grip();
}
