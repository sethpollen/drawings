eps = 0.001;
$fn = 40;

spline_count = 12;

spline_id_max = 7.9;
spline_id_min = 6.6;

screw_hole_id = 4.8;
screw_head_hole_id = 8.7;

shaft_od = 11.6;
arm_base_od = 13.6;
arm_end_od = 9.3;

shaft_length = 20;
arm_radius = 40;
crank_height = 15;
handle_length = 35;

extended = false;

module plug() {
  spline_length = 16;
  screw_hold_length = 7.8;
  
  translate([0, 0, -eps]) {
    linear_extrude(spline_length + eps) {
      circle(d=spline_id_min);
      intersection() {
        circle(d=spline_id_max);
        for (a = [0:5])
          rotate([0, 0, a*30])
            square([100, 1.03], center=true);
      }
    }
    translate([0, 0, spline_length]) {
      linear_extrude(screw_hold_length + eps)
        circle(d=screw_hole_id);
      translate([0, 0, screw_hold_length]) {
        linear_extrude(50)
          circle(d=screw_head_hole_id);
      }
    }
  }
}

module exterior() {
  extension = extended ? 15 : 0;
  
  // Bottom shaft.
  cylinder(h=shaft_length + extension + eps, d=shaft_od);
  
  if (extended)
    translate([0, 0, shaft_length])
      linear_extrude(extension+eps)
        hull()
          circle(d=arm_base_od);
  
  // Crank arm.
  translate([0, 0, shaft_length + extension]) {    
    difference() {
      linear_extrude(crank_height) {
        hull() {
          circle(d=arm_base_od);
          translate([arm_radius, 0])
            circle(d=arm_end_od);
        }
      }
      
      // Cut out the bottom.
      translate([0, -10, 0]) {
        hull() {
          translate([arm_base_od/2, 0, -20-eps])
            cube(20);
          translate([arm_radius-10, 0, -13])
            cube(20);
        }
      }
      
      // Cut out the top.
      scale([-1, 1, 1])
        translate([-arm_radius, -50, crank_height])
          rotate([0, 5, 0])
            translate([arm_radius-50, 0, 0])
              cube(100);
    }
  }
  
  // Handle.
  translate([arm_radius, 0, shaft_length + extension + 7 + eps]) {
    cylinder(h=handle_length-8+eps, d=arm_end_od);
    translate([0, 0, handle_length-8])
      cylinder(h=1, d1=arm_end_od, d2=arm_end_od-2);
  }
}

module piece() {
  rotate([135, 0, 0]) {
    difference() {
      exterior();
      plug();
    }
  }
}

module support() {
  linear_extrude(50)
    offset(-1)
      projection()
        piece();
}

piece();