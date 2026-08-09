use <paddle.scad>

layer = 0.16;

print_position()
intersection_for(z = layer * [4, -4])
translate([0, 0, z])
simple_exterior();

// A reference for positioning the model vertically in the slicer.
translate([-90, 0])
cube(1);