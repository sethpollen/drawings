include <common.scad>
use <base.scad>
use <head.scad>

arm_girth = 8;
arm_length = 12;

torso_breadth = 18;
torso_thickness = 10;
torso_height = 18;

leg_height = 13;
leg_girth = 9;

ARM_DOWN = 1;
ARM_DOWN_FUSED = 2;
ARM_OUTSTRETCHED = 3;
ARM_RAISED = 4;

module basic_body(
  arms=[ARM_DOWN, ARM_DOWN],
  bony=false,
  tall=false,
) {
  actual_leg_height = leg_height + (tall ? 17 : 0);
  // Enderman have a shorter torso to accentuate the tall legs.
  actual_torso_height = torso_height - (tall ? 4 : 0);
  
  difference() {
    union() {
      // Torso.
      if (bony) {
        // Ribs.
        for (a = [0:2])
          translate([0, 0, a*actual_torso_height/5])
            chamfered_box([
              torso_breadth,
              torso_thickness,
              actual_torso_height/5
            ]);
        // The rest of the torso is narrower.
        chamfered_box([
          torso_breadth-4,
          torso_thickness-3,
          actual_torso_height
        ]);
      } else {
        chamfered_box(
          [torso_breadth, torso_thickness, actual_torso_height]);
      }

      // Shoulders.
      for (a = [-1, 1]) {
        scale([a, 1, 1]) {
          arm_type = arms[(a+1)/2];
          translate([torso_breadth/2, 0, 0])
            rotate([0, arm_type == ARM_RAISED ? -45 : 0, 0])
              translate([arm_girth/2, 0, 0])
                chamfered_box([
                  arm_girth+1+2*eps,
                  arm_girth,
                  arm_girth,
                ]);
        }
      }

      // Legs.
      for (a = [-1, 1]) {
        scale([a, 1, 1]) {
          translate([leg_girth/2, 0, actual_torso_height]) {
            hull() {
              chamfered_box(
                [leg_girth, leg_girth, actual_leg_height]);
              translate([0, 0, -2])
                cube(1, center=true);
            }
          }
        }
      }
      
      // Fill the gap between the tops of the legs.
      translate([0, 0, actual_torso_height])
        cube([2, leg_girth-3, 2], center=true);
    }
    
    // Head locking socket.
    locking_socket_bottom();
    
    // Arm locking sockets.
    for (a = [-1, 1]) {
      scale([a, 1, 1]) {
        arm_type = arms[(a+1)/2];
        
        if (arm_type == ARM_OUTSTRETCHED) {
          translate([
            (torso_breadth+arm_girth)/2,
            -arm_girth/2,
            arm_girth/2
          ])
            rotate([90, 0, 0])
              locking_socket_top();
          
        } else if (arm_type == ARM_DOWN) {
          translate([(torso_breadth+arm_girth)/2, 0, arm_girth])
            locking_socket_top();
          
        } else if (arm_type == ARM_RAISED) {
          translate([torso_breadth/2, 0, 0])
            rotate([0, arm_type == ARM_RAISED ? -45 : 0, 0])
              translate([arm_girth/2, 0, 0])
                locking_socket_bottom();
          
        } else {
          // For ARM_DOWN_FUSED, there is no need for a
          // locking socket.
        }
      }
    }
        
    // Baseplate locking socket.
    translate([0, 0, actual_torso_height+actual_leg_height])
      locking_socket_top();
  }
}

module arm(bony=false, tall=false) {
  girth = bony ? arm_girth-2 : arm_girth;
  actual_length = arm_length + (tall ? 10 : 0);
  
  chamfered_box([girth, girth, actual_length]);
  
  // Locking lug.
  translate([0, 0, actual_length])
    locking_lug();
}

module bow() {
  thickness = 3;
  piece_length = 8;

  translate([0, 0, 0])
    chamfered_box([thickness, piece_length*2, thickness]);

  for (a = [-1, 1])
    scale([1, a, 1])
      translate([0, piece_length-1, 0])
        rotate([45, 0, 0])
          translate([0, piece_length/2, -0.5])
            chamfered_box([thickness, piece_length, thickness]);
}
