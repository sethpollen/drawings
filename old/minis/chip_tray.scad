use <base.scad>
include <common.scad>

chip_capacity = 80;
height = 14 + 3.6 * (chip_capacity / 4);

difference() {
  union() {
    // Main exterior.
    chamfered_disk(height, 49);
      
    // Handle on top.
    cylinder(height + 30, 4, 4);
    translate([0, 0, height+30])
      sphere(8);
  }
  
  for (a = [0, 90, 180, 270]) {
    rotate([0, 0, a]) {
      translate([0, 32, 0]) {
        // Vertical shaft with chamfer around the top.
        translate([0, 0, 3])
          chamfered_disk(height, 20.5);
        translate([0, 0, height-1.1])
          chamfered_disk(10, 21.5);
        
        // Cut off some sharp edges.
        translate([0, 21, -eps])
          cylinder(height+2*eps, 18, 18);
        
        // Punch through the bottom, with chamfered edge.
        punch_radius = 15.03;
        hull() {
          for (b = [0, 20]) {
            translate([0, b, 0]) {
              translate([0, 0, -eps])
                cylinder(10, punch_radius, punch_radius);
            }
          }
        }
        hull() {
          for (b = [0, 20]) {
            translate([0, b, 0]) {
              translate([0, 0, -8.9])
                chamfered_disk(10, punch_radius+1);
            }
          }
        }
      }
    }
  }
}
