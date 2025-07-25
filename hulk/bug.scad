include <base.scad>

module support(y, z) {
  length = 10;
  
  translate([0, y, z])
    cube([length, 0.4, 0.6], center=true);
  
  for (a = [-1, 1]) {
    scale([a, 1, 1]) {
      hull() {
        translate([length/2, y, z])
          cube(0.6, center=true);
        translate([length/2, y-2, 0])
          cube([4, 4, 1]);
      }
    }
  }
}

module import_and_position() {
  inflate = 1.75;
  translate([0, 0.4, 0])
    scale(inflate * [1, 1, 1])
      translate([-125, 6, -96.805])
        rotate([90, 0, 0])
          import("fixed/alien.stl");
}

module spike(r=0) {
  rotate([0, r, 0]) {
    hull() {
      linear_extrude(eps)
        square([3, 5], center=true);
      translate([0, 0, 7])
        linear_extrude(eps)
          square([1.6, 0.7], center=true);
    }
  }
}

module alien(spiky=false) {
  // Enlarge slightly.
  scale(1.1 * [1, 1, 1]) {
    difference() {
      import_and_position();

      // Chop off the end of the tail, to reduce overhang.
      translate([0, -0.5, 28.5])
        cube([100, 2, 2], center=true);
    }
    
    if (spiky) {
      translate([0, -6, 19]) rotate([22, 0, 0]) spike();
      translate([0, -7.5, 17.7]) rotate([48, 0, 0]) spike();
      translate([0, -8.4, 16]) rotate([74, 0, 0]) spike();
      
      for (a = [-1, 1]) {
        scale([a, 1, 1]) {
          translate([0.5, -6.75, 18.35]) rotate([35, 0, 0]) spike(35);
          translate([0.5, -7.95, 16.85]) rotate([61, 0, 0]) spike(35);
        }
      }
    }
  }
  
  // Attach supports.
  support(0.44, 5.434);
  support(-9.79, 11.55);
}

module alien_base() {
  difference() {
    union() {
      // Remove the hole.
      base_modified();
      linear_extrude(4)
        circle(9);
    }
    
    // Glue guides.
    translate([0, 0, 3.4])
      for (y = [8.5, -7.6])
        translate([0, y])
          cylinder(r=0.45, h=10);
  }
}

alien_base();
