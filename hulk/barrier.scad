eps = 0.0001;

module torus() {
  r1 = 10;
  r2 = 3;
  rotate_extrude($fn = 50)
    translate([r1, 0])
      circle(r2, $fn = 30);
}

module ball() {
  rotate([54.8, 0, 0]) {
    torus();
    rotate([0, 0, 45]) {
      rotate([90, 0, 0]) torus();
      rotate([0, 90, 0]) torus();
    }
  }
}

module print() {
  up = 9.5;
  difference() {
    translate([0, 0, up])
      ball();
    translate([0, 0, -500 + 0.2])
      cube(1000, center=true);
  }
  linear_extrude(0.2)
    offset(-0.2)
      projection(cut = true)
        translate([0, 0, up-0.1])
          ball();
}

print();