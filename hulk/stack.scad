module stack(h) {
  linear_extrude(h + 0.0001) children(0);
  if ($children > 1)
    translate([0, 0, h]) children(1);
}
