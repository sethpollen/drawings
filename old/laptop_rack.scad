$fa = 5;
$fs = 0.2;

donut_ir = 10;
donut_or = donut_ir+1.7;
donut_core_offset = 30;
donut_core_length = 60;

wall_thickness = 8;
corner_radius = 12;

wall_length = 230;
wall_height = 125;

// Laptop is 15mm thick.
gap = 19;

base_width = 85;
base_thickness = 8;

base_offset = (base_width - (gap + 2*wall_thickness + 4*donut_or)) / 2;

buttress_radius = 8;

module hole_profile() {
  $fn = 8;
  rotate([0, 0, 360/16])
    circle(donut_ir);
}

module donut() {
  translate([0, 0, donut_or+donut_core_offset+base_thickness]) {
    rotate([0, 90, 0]) {
      for (a = [-1, 1], b = [-1, 1]) {
        scale([a, 1, b]) {
          linear_extrude(donut_core_length) {
            difference() {
              translate([0, -donut_or, 0])
                square([donut_or+donut_core_offset, donut_or*2]);
              translate([donut_core_offset, 0, 0])
                hole_profile();
            }
          }
          difference() {
            translate([0, 0, donut_core_length-13]) {
              rotate([90, 0, 0]) {
                rotate_extrude(angle=90) {
                  difference() {
                    translate([0, -donut_or, 0])
                      square([donut_core_offset+0.4, 2*donut_or]);
                    translate([donut_core_offset+4.2, 0, 0])
                      hole_profile();
                  }
                }
              }
            }
            linear_extrude(1000)
                translate([donut_core_offset, 0, 0])
                  hole_profile();
          }
        }
      }
    }
  }
  
  // Fillet beneath.
  translate([0, 0, base_thickness/2])
    cube([donut_core_length*2, donut_or*2, base_thickness], center=true);
}

module wall_corner() {
  rotate([90, 0, 0]) {
    rotate_extrude(angle=90) {
      hull() {
        translate([corner_radius, 0, 0])
          circle(wall_thickness/2);
        translate([0, -wall_thickness/2, 0])
          square([0.001, wall_thickness]);
      }
    }
  }
}

module wall() {
  hull() {
    for (a = [-1, 1]) {
      scale([a, 1, 1]) {
        // Wall base.
        linear_extrude(1)
          translate([
            wall_length/2 - wall_thickness/2,
            0,
            0
          ])
            circle(wall_thickness/2);
          
        translate([
          wall_length/2 - corner_radius - wall_thickness/2,
          0,
          wall_height + base_thickness - corner_radius - wall_thickness/2
        ])
          wall_corner();
      }
    }
  }
}

module walls() {
  for (a = [-1, 1])
    translate([0, a * (wall_thickness + gap)/2, 0])
      wall();
}

module base_corner() {
  intersection() {
    cube([100, 100, 100]);
    rotate_extrude(angle=90) {
      hull() {
        translate([corner_radius, 0, 0])
          circle(base_thickness);
        translate([0, -base_thickness, 0])
          square([0.001, base_thickness*2]);
      }
    }
  }
}

module base() {
  translate([0, -base_offset, 0])
    hull()
      for (a = [-1, 1], b = [-1, 1])
        scale([a, b, 1])
          translate([
            wall_length/2 - corner_radius - base_thickness,
            base_width/2 - corner_radius - base_thickness,
            0
          ])
            base_corner();
}

module buttress() {
  difference() {
    hull() {
      for (a = [
        [base_width/2-buttress_radius+base_offset, 0],
        [gap/2, wall_height]
      ])
        translate([0, a[0], a[1]])
          linear_extrude(0.001)
            circle(buttress_radius);
      
      linear_extrude(0.001)
        translate([0, gap/2+wall_thickness/2, 0])
          square(buttress_radius*2, center=true);
    }
    
    cube([300, gap, 300], center=true);
  }
}

module laptop() {
  color("orange")
    translate([0, 0, 210/2+base_thickness+0.5])
      cube([305, 15, 210], center=true);
}

module preview() {
  base();
  for (a = [-1, 1])
    scale([a, -1, 1])
      translate([0.6*wall_length/2, 0, 0])
        buttress();
  walls();
  translate([0, donut_or+gap/2+wall_thickness])
    donut();
}

rotate([0, 0, 45])
  preview();

//laptop();
