module chain() {
  if ($children >= 2)
  for (i = [0:$children-2])
  hull() {
    children(i);
    children(i+1);
  }
}

module makelayer(z) {
  translate([0, 0, z])
  linear_extrude(0.0001)
  children();
}
