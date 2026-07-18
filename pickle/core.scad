use <paddle.scad>

layer = 0.15;

intersection_for(z = layer * [
  // Floor:
  //   Exterior | solid x2 | half x3 | solid x1 | Interior
  5,
  // Ceiling:
  //   Exterior | solid x3 | half x2 | solid x2 | Interior
  -5
])
translate([0, 0, z])
simple_exterior();

// A reference for positioning the model vertically in Cura.
translate([-50, 0])
cube(1);