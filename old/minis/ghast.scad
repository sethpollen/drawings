use <base.scad>
use <common.scad>
include <head.scad>

module ghast_legs() {
  for (a = [-1, 1], b = [-1, 1]) {
    translate([7*a, 7*b, 0]) {
      chamfered_box([7, 7, 13]);
      translate([0, 0, 13])
        locking_lug();
    }
  }
}

module ghast_head() {
  difference() {
    chamfered_box([30, 30, 26]);
 
    translate([0, -15, 6])
      scale([1.1, 1, 1.3])
        face([
          [0, 0, 0, 0, 0, 0, 0, 0],
          [1, 1, 1, 0, 0, 1, 1, 1],
          [0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 1, 1, 1, 1, 0, 0],
        ]);
    
    // Sockets for the tops of the legs.
    for (a = [-1, 1], b = [-1, 1])
      translate([7*a, 7*b, 0])
        locking_socket_bottom();
  }
  
  translate([0, 0, 26 - eps])
    four_studs()
      stud(SMALL_STUD);
}

module ghast_preview() {
  color(c = [0.8, 0.8, 0.8]) {
    translate([0, 0, 0]) base(lug=false);
    translate([0, 0, 3.5]) ghast_legs();
    translate([0, 0, 16.5]) ghast_head();
    translate([0, 0, 42.5]) light_weapon();
    translate([0, 0, 46]) light_armor();
  }
}

ghast_head();

translate([40, 0, 0]) {
  base(lug=false);
  translate([0, 0, 3.5-eps])
    ghast_legs();
}
