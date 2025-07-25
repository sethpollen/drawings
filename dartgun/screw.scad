include <common.scad>

// #8 machine screw.
screw_od = 4;
washer_od = 11.3;
screw_head_od = 8;

screw_hole_id = screw_od + 0.5;

// #8 hex nut.
nut_min_od = 8.6;
nut_max_od = 9.6;
nut_thickness = 3.2;

nut_cavity_height = nut_thickness + 0.2;

module nut_cavity() {
  linear_extrude(nut_cavity_height)
    offset(loose/2)
      circle(d=nut_min_od*2/sqrt(3), $fn = 6);
}
