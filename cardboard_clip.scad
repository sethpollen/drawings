length = 23;
gap_inner = 2.42;
pinch_angle = 1.3;
gauge = 1.8;

flare_length = 3;
flare_angle = 18;

eps = 0.001;

module leg_2d() {
  spread = gap_inner/2 + gauge/2;
  
  rotate([0, 0, 45])
    square([spread*sqrt(2), eps]);
  translate([spread, spread]) {
    rotate([0, 0, pinch_angle]) {
      square([eps, length - spread]);
      translate([0, length - spread])
        rotate([0, 0, -flare_angle])
          square([eps, flare_length]);
    }
  }
}

module piece_2d(n=3) {
  $fn = 30;
  roundoff = 0.6;
  
  offset(-roundoff)
    offset(gauge/2 + roundoff)
      for (a = [1:n])
        rotate([0, 0, a*90])
          for (b = [-1, 1])
            scale([b, 1])
              leg_2d();
}

linear_extrude(40)
  piece_2d(3);