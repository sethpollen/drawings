include <common.scad>

module ring_profile() {
  translate([12, 0, 0])
    polygon([
      [0, 0],
      [3, 0],
      [3, 0.9],
      [2.3, 1.6],
      [0.7, 1.6],
      [0, 0.9],
    ]);
}

module ring() {
  rotate_extrude(angle=360)
    ring_profile();
}

module ring_hole() {
  rotate_extrude(angle=360)
    offset(r = 0.5)
      ring_profile();
}

module base(lug=true) {
  difference() {
    union() {
      chamfered_disk(3.5, 20);
      
      // A lug for gluing a body.
      if (lug) {
        translate([0, 0, 3.5])
          locking_lug();
      }
    }
    ring_hole();
  }
}

module base_chip() {
  base(lug=false);
  translate([0, 0, 3.5])
    ring();
}

// Demo.
base_chip();

