width = 4.5;
depth = 2.4;
height = 16;
$fn = 30;

inset = 0.6;
pipe_radius = depth - inset;

module middle() {
  rotate([90, 0, 0]) {
    hull()
      for (x = [depth, height-depth])
        translate([x, 0, 0])
          cylinder(h=width, r=depth);
  }
}

module octagon() {
  intersection_for(a = [0, 45])
    rotate([0, 0, a])
      square(pipe_radius*2, center=true);
}

module elbow() {
  rotate_extrude(angle = 90)
    translate([pipe_radius, 0])
      octagon();
}

module pipe_pack() {
  translate([-height/2, width/2, 0])
    middle();
  
  for (a = [-1, 1]) {
    scale([1, a]) {
      for (b = [-1, 1])
        scale([b, 1])
          translate([height/2 - pipe_radius - depth, width/2, 0])
            elbow();
      translate([-height/2 + pipe_radius + depth, width/2 + pipe_radius, 0])
        rotate([0, 90, 0])
          linear_extrude(height - 2*pipe_radius - 2*depth)
            octagon();
    }
  }
}

module tilted_pack() {
  for (a = [-1, 1]) {
    scale([1, a]) {
      translate([0, 1.4]) {
        rotate([0, 0, -10]) {
          intersection() {
            pipe_pack();
            translate([0, 50, 0])
              cube(100, center=true);
          }
        }
      }
    }
  }
  hull() {
    for (a = [-1, 1]) {
      scale([1, a]) {
        translate([0, 1.4]) {
          rotate([0, 0, -10]) {
            intersection() {
              pipe_pack();
              translate([0, 1, 0])
                cube([100, 2, 100], center=true);
            }
          }
        }
      }
    }
  }
}

module half() {
  difference() {
    translate([0, 0, 0.8])
      tilted_pack();
    translate([0, 0, -500])
      cube(1000, center=true);
  }
}

module print() {
  linear_extrude(0.2)
    offset(-0.2)
      projection(cut = true)
        translate([0, 0, -0.1])
          half();
  intersection() {
    half();
    translate([0, 0, 500.2])
      cube(1000, center=true);
  }
}

print();