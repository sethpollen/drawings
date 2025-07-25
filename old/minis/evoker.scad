use <base.scad>
include <body.scad>
use <head.scad>

module evoker_arm() {
  arm();
}

module evoker_body() {
  basic_body(arms=[ARM_RAISED,ARM_RAISED]);
}

module evoker_preview() {
  color(c = [0.8, 0.8, 0.8]) {
    translate([0, 0, 34.5]) evoker_head();
    translate([0, 0, 46.5]) light_weapon();
    translate([0, 0, 50]) light_armor();
    translate([20, 0, 40])
      rotate([0, 225, 0])
        evoker_arm();
    translate([-20, 0, 40])
      rotate([0, -225, 0])
        evoker_arm();
  }
  color(c = [0.4, 0.4, 0.4]) {
    translate([0, 0, 0]) base();
    translate([0, 0, 34.5])
      rotate([0, 180, 0]) evoker_body();
  }
}

// 1 for body, 2 for head and arms.
resin = 1;

if (resin == 1) {
  evoker_body();
  translate([0, 35, 0]) base();
}
if (resin == 2) {
  evoker_head();
  translate([20, 0, 0]) evoker_arm();
  translate([-20, 0, 0]) evoker_arm();
}
