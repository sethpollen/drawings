use <base.scad>
include <body.scad>
use <common.scad>
use <head.scad>

module creeper_body() {
  base(lug=false);
  
  // Main body.
  translate([0, 0, 8.5-eps])
    chamfered_box([torso_breadth, torso_thickness, 22]);
  
  // Legs.
  for (a = [-1, 1], b = [-1, 1])
    scale([a, b, 1])
      translate([torso_breadth/4, 6.5, 3.5-eps])
        chamfered_box([torso_breadth/2, 7, 12]);
      
  // Head locking lug.
  translate([0, 0, 30.5-eps]) locking_lug();
      
  translate([0, 0, 8.5-eps]) {
    difference() {
      // Fillet between the legs.
      cube([torso_breadth-1, 7+eps, 10], center=true);
      
      // Side-to-side cutout.
      translate([-20, 0, 0])
        rotate([0, 90, 0])
          linear_extrude(40)
            polygon([
              [10, 4+eps],
              [2, 4+eps],
              [0, 0],
              [2, -4-eps],
              [10, -4-eps],
            ]);

      // Front-to-back cutout.
      rotate([0, 0, 90])
        translate([-20, 0, 0])
          rotate([0, 90, 0])
            linear_extrude(40)
              polygon([
                [10, 9+eps],
                [-0.2, 9+eps],
                [4, 0],
                [-0.2, -9-eps],
                [10, -9-eps],
              ]);
    }
  }
}

module creeper_preview() {
  color(c = [0.5, 0.9, 0.3]) {
    translate([0, 0, 0]) creeper_body();
    translate([0, 0, 30.5]) creeper_head();
    translate([0, 0, 40.5]) light_weapon();
    translate([0, 0, 44]) light_armor();
  }
}

// Printable.
creeper_body();
translate([0, -35, 0]) creeper_head();
