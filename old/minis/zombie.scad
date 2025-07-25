use <base.scad>
include <body.scad>
use <head.scad>

module zombie_arm() {
  arm();
}

module zombie_body() {
  basic_body(arms=[ARM_OUTSTRETCHED,ARM_OUTSTRETCHED]);
}

module zombie_preview() {
  color(c = [0.5, 0.9, 0.3]) {
    translate([0, 0, 34.5]) zombie_head();
    translate([0, 0, 44.5]) light_weapon();
    translate([0, 0, 48]) light_armor();
    translate([13, -16, 30.5])
      rotate([-90, 0, 0]) zombie_arm();
    translate([-13, -16, 30.5])
      rotate([-90, 0, 0]) zombie_arm();
  }
  color(c = [0.6, 0.0, 0.6]) {
    translate([0, 0, 0]) base();
    translate([0, 0, 34.5])
      rotate([0, 180, 0]) zombie_body();
  }
}

// 1 for body, 2 for head and arms.
resin = 2;

if (resin == 1) {
  zombie_body();
  translate([0, 27, 0]) base();
}
if (resin == 2) {
  zombie_head();
  translate([15, 0, 0]) zombie_arm();
  translate([-15, 0, 0]) zombie_arm();
}
