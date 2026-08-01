// Little posts for anchoring rubber bands.

include <common.scad>

band_post_diameter = 5 - loose;
post_hole_depth = 6;
post_hole_width = band_post_diameter + loose;

module band_post(cavity_width) {
  length = post_hole_depth*2 + cavity_width - 1;

  for (x = [0, length - post_hole_depth])
    translate([x, 0, 0])
      chamfered_cube([post_hole_depth, band_post_diameter, band_post_diameter], 0.5);
  
  translate([1, band_post_diameter/2, band_post_diameter/2])
    rotate([0, 90, 0])
      cylinder(length-2, d=band_post_diameter);
}
