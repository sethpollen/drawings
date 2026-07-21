use <paddle.scad>

layer = 0.15;

intersection_for(z = layer * [
  /* Floor: 6 total layers
       <interior>
         solid
         solid   <- bottom layer of core
         50%
         50%
         solid
         solid
       <exterior>
  */
  4,

  /* Ceiling: 8 total layers
       <exterior>
         solid (partially to be sanded off)
         solid
         solid
         50%
         50%
         solid   <- top layer of core
         solid
         solid
       <interior>
  */
  -5
])
translate([0, 0, z])
simple_exterior();

// A reference for positioning the model vertically in Cura.
translate([-50, 0])
cube(1);