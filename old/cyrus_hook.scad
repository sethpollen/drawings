include <morph.scad>

$fa = 5;
$fs = 0.5;
$zstep = 0.1;

length = 90;
thickness = 6.5;
gap = 20;
extension = 12;
height = 17;

module profile() {
  intersection() {
    square(100);
    difference() {
      circle(thickness + gap);
      translate([1, gap*0.4])
        circle(gap*0.6);
    }
  }

  chamfer = 2;

  difference() {
    union() {
      // Main plate.
      translate([-length+gap+thickness, -thickness])
        square([length, thickness]);

      // Hook extension.
      translate([-extension, gap])
        square([extension, thickness]);
    }

    for (a = [[-extension, gap], [-extension, gap+thickness], [-length+gap+thickness, 0]])
      translate(a)
        rotate([0, 0, 45])
          square(chamfer, center=true);
  }
}

screw_head_diameter = 8.2;
screw_diameter = 4;

module hook() {
  // Flip the brim side.
  scale([-1, 1, 1]) {
    difference() {
      morph([
        [0, [-1.2]],
        [0.4, [-0.8]],
        [2, [0]],
        [height-2, [0]],
        [height, [-1]],
      ]) {
        offset($m[0])
          profile();
      }
    
      for (x = [-22, -52]) {
        translate([x, 0.01, height/2]) {
          rotate([90, 0, 0]) {
            cylinder(h=0.301, d=screw_head_diameter);
            translate([0, 0, 0.3])
              cylinder(h=screw_head_diameter/2, d1=screw_head_diameter, d2=0);
            cylinder(h=thickness+1, d=screw_diameter);
          }
        }
      }
    }
  }
}

hook();