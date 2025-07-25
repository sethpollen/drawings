use <base.scad>
include <body.scad>
use <head.scad>

module hero_arm() {
  arm();
}

module hero_body() {
  basic_body(arms=[ARM_DOWN,ARM_DOWN]);
}

module hero_preview() {
  color(c = [0.8, 0.7, 0.4]) {
    translate([0, 0, 34.5]) hero_head();
    translate([0, 0, 44.5]) light_weapon();
    translate([0, 0, 48]) light_armor();
    translate([13, 0, 14.5]) hero_arm();
    translate([-13, 0, 14.5]) hero_arm();
  }
  color(c = [0.3, 0.7, 1.0]) {
    translate([0, 0, 0]) base();
    translate([0, 0, 34.5])
      rotate([0, 180, 0]) hero_body();
  }
}

// 1 for body, 2 for head and arms.
resin = 1;

if (resin == 1) {
  hero_body();
  translate([0, 35, 0]) base();
}
if (resin == 2) {
  hero_head();
  translate([20, 0, 0]) hero_arm();
  translate([-20, 0, 0]) hero_arm();
}
