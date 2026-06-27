foam_side = 2;
foam_count = 8;

module foam(offs) {
  translate(
    (-offs - foam_side) * [1, 1, 1]
    // Center it in the X and Y directions.
    - (foam_side*foam_count/2) * [1, 1, 0]
  )
  for (x = [1:foam_count], y = [1:foam_count], z = [1:foam_count])
  if ((x + y + z) % 2 == 0)
  translate(foam_side * [x, y, z])
  cube(foam_side + 2*offs);
}

module piece(offs) {
  translate([0, 10, 3])
  rotate([90, 0, 0])
  linear_extrude(20)
  circle(r=7+offs);
}

piece(0);

for (i = [0.2, 0.4, 0.6])
color([1, 1, 1])
intersection() {
  piece(i);
  foam(0.6-1.5*i);
}