use <paddle.scad>

inset = 4 * 0.15;

intersection_for(z = inset * [-1, 1])
translate([0, 0, z])
simple_exterior();

// A reference for positioning the model vertically in Cura.
translate([-50, 0])
cube(1);