include <common.scad>
use <base.scad>
include <body.scad>
use <head.scad>

module skeleton_arm(with_bow=false) {
  arm(bony=true);
  if (with_bow) {
    bow();
  }
}

module skeleton_body() {
  basic_body(arms=[ARM_DOWN_FUSED,ARM_OUTSTRETCHED], bony=true);
  translate([-13, 0, 20-eps])
    rotate([0, 180, 0])
      skeleton_arm();
}

module skeleton_preview() {
  color(c = [0.8, 0.8, 0.8]) {
    translate([0, 0, 0]) base();
    translate([0, 0, 34.5])
      rotate([0, 180, 0]) skeleton_body();
    translate([0, 0, 34.5]) skeleton_head();
    translate([-13, -16, 30.5]) rotate([-90, 0, 0])
      skeleton_arm(with_bow=true);
    translate([0, 0, 44.5]) light_weapon();
    translate([0, 0, 48]) light_armor();
  }
}

// Printable.
skeleton_body();
translate([0, 26, 0]) base();
translate([0, -15, 0]) skeleton_head();
translate([-21, 0, 0]) skeleton_arm(with_bow=true);
