include <common.scad>
include <barrel.scad>
include <post.scad>

// TODO: really need to rework this whole thing to translate it slightly
// in the y dimension. Centering the receiver is dumb.

// TODO: make the grip more reusable between this and foregrip.scad.

// TODO:
slider_width = barrel_width + 2*enclosure_wall;
slider_height = barrel_height + 2*enclosure_wall;
 
receiver_length = 95;
trigger_pivot_diameter = 6;
trigger_pivot_x = 3;
trigger_pivot_y = (71-receiver_length)/2;
grip_length = 53;
grip_height = 85;
trigger_length = 31;
grip_circle_diameter = slider_width*0.9;

grip_lug_dims = [6, 25, 57];

module grip() {
  // Lug to hold the two halves together.
  grip_lug_dims = [6, 25, 57];
  lug_translate = [0, 6, 10];
  lug_rotate = [14, 0, 0];
  
  difference() {
    intersection() {
      hull() {
        for (y = (grip_length/2 - grip_circle_diameter/2) * [-1, 1]) {
          translate([0, y + grip_height*0.25, 0])
            linear_extrude(eps)
              circle(grip_circle_diameter/2-2);
          translate([0, y + grip_height*0.25, 2])
            linear_extrude(eps)
              circle(grip_circle_diameter/2);
          translate([0, y, grip_height])
            sphere(grip_circle_diameter/2);
        }
      }
        
      translate([-slider_width/2 + 4, -100, 0])
        cube([slider_width/2 - 4, 200, grip_height + grip_circle_diameter/2]);
    }
    
    // Cavity for interlocking lug.
    translate(lug_translate - [grip_lug_dims.x + 0.5, 0, 0])
      rotate(lug_rotate)
        translate([0, -loose/2, -loose/2])
          cube(grip_lug_dims + [0.5 + eps, loose, loose]);
  }
}

module grip_lug() {
  rotate([90, 0, 0])
    // Subtract one layer (0.2mm) to make sure it fits nicely.
    chamfered_cube(grip_lug_dims + [grip_lug_dims.x, -0.2, 0], 0.9);
}

string_hollow_diameter = 9;

module receiver() {
  // TODO: fix
  trigger_cavity_y = 25.3;

  difference() {
    union() {
      difference() {
        // Main body of receiver.
        translate([-barrel_height/2 - enclosure_wall, -receiver_length/2, -barrel_width/2 - enclosure_wall])
          cube([barrel_height + 2*enclosure_wall, receiver_length, barrel_width/2 + enclosure_wall]);
        
        // Chamfer sharp corners near the grip.
        rear_chamfer = 5.6;
        translate([0, receiver_length/2, -slider_width/2])
          rotate([45, 0, 0])
            cube([slider_height+1, rear_chamfer, rear_chamfer], center=true);
        translate([20, receiver_length/2, -slider_width/2 - 5.25])
          rotate([35, 0, -45])
            cube([slider_height+1, rear_chamfer*3, rear_chamfer*3], center=true);
        translate([slider_height/2, receiver_length/2, -slider_width/2]) {
          rotate([0, 45, 0]) {
            hull() {
              cube([rear_chamfer, receiver_length + 10, rear_chamfer], center=true);
              cube([eps, receiver_length + 80, eps], center=true);
            }
          }
        }
        
        // Barrel cavities.
        translate([0, -50 + trigger_cavity_y - receiver_length/2, 0])
          cube([barrel_height + loose, 100, barrel_width + loose], center=true);
        
        // Barrel trunnion cavities.
        translate([0, -trunnion_cav_length/2 + trigger_cavity_y - receiver_length/2, 0])
          cube([barrel_height + loose, trunnion_cav_length, barrel_width + loose + 2*trunnion_width], center=true);
      }
       
      // Grip.
      translate([grip_height + slider_height/2, (155-receiver_length)/2 + 0.5, 0])
        rotate([0, -90, 0])
          grip();
      
      // Barrel intrusion.
      difference() {
        translate([0, trigger_cavity_y - receiver_length/2 + 1 + eps, 0])
          rotate([90, 90, 0])
            intrusion(trigger_cavity_y - string_hollow_diameter/2 + 1);
        
        // Remove top half.
        translate([0, 0, 100 + eps])
          cube(200, center=true);
      }
    }
    
    // Angle the back of the receiver.
    translate([-30, 18, -slider_width/2 - eps])
      rotate([0, 0, 45])
        cube([50, 30, slider_width]);
    
    // TODO: retune trigger pull

    // Trigger slot.
    translate([-1 - eps, trigger_cavity_y - receiver_length/2 - eps, -trigger_cav_width/2 - eps]) {
      linear_extrude(trigger_cav_width/2 + 2*eps) {
        union() {
          square([slider_height/2 + 12, receiver_length - trigger_cavity_y - (receiver_length - 53.7) + 2*eps]);
          hull() {
            square([slider_height/2 + 5, receiver_length - trigger_cavity_y - (receiver_length - 85) + 2*eps]);
            translate([-9, 0]) square([eps, 40]);
          }
        }
      }
    }
    
    // Hollow in front to fit over the string in the collapsed position, so that the two
    // sliders can touch even with the string between them.
    translate([0, -receiver_length/2, -20])
      linear_extrude(20)
        octagon(string_hollow_diameter);
    
    // Slight cutout to strengthen the connection of the pivot pin against shearing.
    translate([trigger_pivot_x, trigger_pivot_y, -trigger_cav_width/2 - 2])
      linear_extrude(10)
        circle(d=trigger_pivot_diameter-3.5);
    
    // Rubber band post holes.
    translate([0, 0, -trigger_cav_width/2 - post_hole_depth])
      linear_extrude(post_hole_depth + eps)
        for (xy = [
          [3, 32],
          [12, 32],
          [21, 32],
          [21, 23],
          [21, 13],
        ])
          translate(xy)
            square(post_hole_width, center=true);
  }
  
  // Trigger pivot post.
  translate([0, 0, -trigger_cav_width/2]) {
    linear_extrude(trigger_cav_width/2) {
      translate([trigger_pivot_x, trigger_pivot_y]) {
        difference() {
          circle(d=trigger_pivot_diameter);
          circle(d=trigger_pivot_diameter-3.5);
        }
      }
    }
  }
  
  // Print aids.
  translate([0, 0, -slider_width/2]) {
    linear_extrude(0.4) {
      translate([-slider_height/2 + 5.5, -receiver_length/2 - 5])
        square(10, center=true);
      translate([-slider_height/2 - 5, -receiver_length/2 + 5.5])
        square(10, center=true);
    }
  }
  
  // Trigger guard.
  trigger_guard_width = 5;
  translate([slider_height/2 + trigger_length - 3.3, 0, -trigger_guard_width]) {
    linear_extrude(trigger_guard_width) {
      translate([0, -35]) square([4, 55]);
      translate([-30, -receiver_length/2]) square([20, 4]);
      hull() {
        translate([0, -35]) square([4, 2]);
        translate([-10, -receiver_length/2]) square([2, 4]);
      }
    }
  }
}

module trigger_2d() {  
  rod_length = 40;
  ring_diameter = trigger_pivot_diameter+9;

  // Pivot.
  difference() {
    $fn = 40;
    union() {
      hull() {
        circle(d=ring_diameter);
        
        rotate([0, 0, -10]) {
          translate([-5, trigger_width/2 - 4])
            square([ring_diameter + 5, trigger_offset + 4]);
        }
        
        // Forward stop.
        stop_length = 16;
        stop_thickness = 4;
        translate([0, -7.69])
          square([stop_length, stop_thickness]);
      }
      
      // Main rod.
      hull() {
        translate([0, -rod_length]) {
          translate([0, 8]) square([5, eps]);
          translate([0, 0]) square([5, eps]);
          translate([1, -10]) square(eps);
        }
      }
      hull() {
        translate([0, 8-rod_length]) square([5, eps]);
        translate([-ring_diameter/2, 0]) square([ring_diameter/2+2, eps]);
      }
      
      // Trigger.
      trigger_offset = 14;
      rotate([0, 0, -10]) {
        translate([10, trigger_offset]) {
          offset(r=trigger_width/2) {
            intersection() {
              // Limit the arc with a box.
              translate([0, -10])
                square([trigger_length, 20]);
              
              // Arc.
              arc_radius = 90;
              translate([7, -arc_radius]) {
                difference() {
                  $fn = 90;
                  circle(arc_radius);
                  circle(arc_radius-0.01);
                }
              }
            }
          }
        }
      }
    }
  }
    
  // String catch.
  catch_round = 3;
  catch_top_x = -barrel_gap/2 - catch_round - 1;
  difference() {
    hull() {
      translate([1, -rod_length]) {
        circle(d=catch_round);
        
        translate([0, -10+catch_round/2])
          circle(d=catch_round);
        
        translate([catch_top_x, 0])
          circle(d=catch_round);
      }
    }
    
    // Make the holding face slightly concave, so that the string doesn't
    // torque the trigger when under tension.
    circle(norm([rod_length, 1+catch_top_x]) - catch_round/2, $fn=180);
  }
}

// Print with 40% cubic infill.
module trigger() {
  difference() {
    union() {
      // Unchamfered part.
      translate([0, 0, -trigger_width/2+1.2])
        linear_extrude(trigger_width-2.4)
          trigger_2d();
      
      // Chamfers. Use big chamfers for two reasons:
      //   1. It helps the string slide off the catch.
      //   2. It makes the trigger feel nice.
      for (a = [-1, 1], b = [0:0.2:1])
        scale([1, 1, a])
          translate([0, 0, -trigger_width/2+b])
            linear_extrude(0.2)
              offset(b-1.2 - (a == 1 && b == 0 ? 0.2 : 0))
                trigger_2d();
    }
  
    // Slot for rubber band.
    translate([-0.5, 16.5, -1]) {
      difference() {
        linear_extrude(trigger_width)
          rotate([0, 0, -65])
            square([13, 30], center=true);
        linear_extrude(trigger_width/2 + 1 + eps, scale=1.4)
          circle(d=5);
      }
    }
    
    // Cut out the pivot hole, with just enough chamfer to prevent elephant foot.
    pivot_hole_diameter = trigger_pivot_diameter + extra_loose;
    for (a = [-1, 1]) {
      scale([1, 1, a]) {
        translate([0, 0, -trigger_width/2-eps]) {
          cylinder(trigger_width, d=pivot_hole_diameter);
          cylinder(0.5, d1=pivot_hole_diameter+1, d2=pivot_hole_diameter);
        }
      }
    }
  }
}

// TODO: trigger can be made slimmer now, with smaller barrel gap.

module preview(pulled=false) {
  receiver();
  translate([trigger_pivot_x, trigger_pivot_y, 0])
    rotate([0, 0, pulled ? 11 : 0])
      trigger();
}

receiver();