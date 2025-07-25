$fn = 60;
shaft = 15;

cylinder(h=shaft, r=1.33);

translate([0, 0, shaft]) {
  difference() {
    union() {
      hull() {
        cylinder(h=0.001, r=1.33);
        translate([0, 0, 2])
          scale([2, 1, 1])
            cylinder(h=0.001, r=1.33);
      }
      hull() {
        translate([0, 0, 2])
          scale([2, 1, 1])
            cylinder(h=0.001, r=1.33);
        translate([0, 0, 8])
          cylinder(h=0.001, r=0.5);
      }
    }
    for (a = [-1, 1]) {
      scale([1, a, 1]) {
        translate([0, 2.33, 0]) {
          scale([2, 1, 1]) {
            hull() {
              cylinder(h=0.001, r=1);
              translate([0, 0, 7])
                cylinder(h=0.001, r=1.67);
            }
          }
        }
      }
    }
  }
}

translate([0, 0, 9]) {
  rotate([0, 90, 0]) {
    for (a = [-1, 1]) {
      scale([1, 1, a*0.8]) {
        hull() {
          linear_extrude(0.001) rotate([0, 0, 45]) square(1.33*sqrt(2), center=true);
          translate([0, 0, 4.5])
            linear_extrude(0.001) rotate([0, 0, 45]) square(1.33*sqrt(2), center=true);
          translate([0, 0, 5.5])
            linear_extrude(0.001) rotate([0, 0, 45]) square(0.5, center=true);
        }
      }
    }
  }
}