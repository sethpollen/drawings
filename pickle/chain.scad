module chain() {
  if ($children >= 2)
  for (i = [0:$children-2])
  hull() {
    children(i);
    children(i+1);
  }
}

// If r=0, we create a linear chain. Otherwise, we create a curved
// chain with the given radius of curvature. A high value of r will
// give something close to r=0.
module mklayer(z, r=0) {
  if (r == 0) {
    translate([0, 0, z])
    linear_extrude(0.0001)
    children();
  } else {
    translate([r, 0, 0])
    rotate([0, 360*z/(2*PI*r), 0])
    translate([-r, 0, 0])
    linear_extrude(0.0001)
    children();
  }
}
