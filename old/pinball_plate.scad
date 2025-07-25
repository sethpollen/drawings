for (a = [true, false]) {
  translate([0, 0, a ? 0 : 0.2]) {
    linear_extrude(a ? 0.2 : 2.6) {
      offset (a ? -0.3 : 0) {
        difference() {
          square([144, 72]);
          for (x = [0, 144])
            translate([x, 0])
              rotate([0, 0, 45])
                square(5.5*sqrt(2), center=true);
        }
      }
    }
  }
}

for (x = [33, 144 - 8 - 33]) {
  translate([x, 0]) {
    hull() {
      translate([0, 0, 2.6])
        cube([8, 6, 0.001]);
      translate([0, -3, 4])
        cube([8, 5, 2]);
    }
  }
}

linear_extrude(0.4)
  for (x = [0, 144], y = [0, 72])
    translate([x, y])
      square(9, center=true);