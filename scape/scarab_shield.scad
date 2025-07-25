$fn=70;

ma = 68;
mb = 45;

module piece_2d() {
  hull()
    for (a = [-1, 1])
      scale([a, 1])
        translate([ma-mb, 0])
          circle(r=mb);
}

difference() {
  linear_extrude(12)
    piece_2d();
  translate([0, 0, 7])
    linear_extrude(10)
      offset(-5)
        piece_2d();
}