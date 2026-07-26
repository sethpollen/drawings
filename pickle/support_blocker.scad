use <paddle.scad>

// Prevent support from being generated inside the knurl grooves.

linear_extrude(40)
projection(cut=true)
translate([0, 0, -0.4])
bottom($opt_knurl = false, $opt_fingers = false);
