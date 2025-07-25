include <common.scad>
use <../grip.scad>
use <../morph.scad>

// A brim is a 0.2mm layer printed near an edge which is likely to warp.
// The edge should be chamfered outwards at 45 degrees. The brim should
// be place this far from the bottom of the edge, so it barely touches
// the chamfer.
brim_offset = 0.3;

// Convention is to point the gun barrel along the Y axis, in the positive
// direction.

receiver_height = 9;
receiver_width = 22;

slide_channel_width = 10;

// Z-distance from top of receiver to center of rails.
slide_rail_drop = 4;

release_slide_length = 25;
// TODO: lengthen
trigger_slide_length = 67;

plate_thickness = 2;
plate_length = release_slide_length+13;

receiver_back_offset = 2;
trigger_back_offset = 20;

trigger_travel = 10;

receiver_length = plate_length + trigger_slide_length + trigger_travel + receiver_back_offset;

lug_width = 5;
lug_radius = 2.5;

// Center-to-center spacing. Add 1 for the extra offset on the release.
outer_lug_spacing = receiver_length + 2*lug_radius + 1;

spring_channel_center_inset = 1.5;
spring_wire_radius = 0.4;

spring_post_radius = 2;

action_width = 6;
action_slot_width = action_width + 3*loose_clearance;

mag_height = 25;

trigger_finger_height = 27;
trigger_rail_drop = trigger_finger_height-4;

module spring_post() {
  morph([
    [0, [0]],
    [spring_wire_radius*2, [0]],
    [spring_wire_radius*2+1.3, [1.7]],
  ])
    translate([0, $m[0], 0])
      circle(spring_post_radius);
}

// A generic sliding block that fits into the receiver channel and has a
// spring cavity and spring post.
module slide(length, width, spring_channel_length, bottom_offset, chamfer_back=true) {
  height = receiver_height - bottom_offset - loose_clearance;

  difference() {
    union() {
      // Main exterior.
      translate([-width/2, -length, 0])
        cube([width, length, height]);

      // Rails.
      for (a = [-1, 1]) {
        scale([a, 1, 1]) {
          translate([width/2, -length/2, height + loose_clearance - slide_rail_drop]) {
            difference() {
              square_rail(length, 1.5);
              
              // Slightly taper the ends of the rails, to reduce jamming.
              for (b = [-1, 1], c = [-1, 1])
                scale([1, b, c])
                  translate([0, 22, 0])
                    rotate([-1.5, 0, 0])
                      translate([1.5, 0, 0])
                        rotate([0, -45, 0])
                          cube([10, length, 10]);
            }
          }
        }
      }
    }
    
    // Chamfer the edges so that any elephant foot doesn't interfere with
    // the sliding.
    for (x = width/2 * [-1, 1], z = [0, height])
      translate([x, 0, z])
        square_rail(1000, major_radius=0.5);
    for (z = [0, height])
      translate([0, -length, z])
        rotate([0, 0, 90])
          square_rail(1000, major_radius=0.5);
    
    // Chamfer the sides of the ends.
    for (a = [-1, 1])
      scale([a, 1, 1])
        translate([(width-1)/2, -length, 0])
          rotate([0, 0, -45])
            cube(10);
    
    if (chamfer_back) {
      // This is a more aggressive chamfer, in case the back of the slide channel
      // has binding edges on it. It's OK to give up some rail length, as
      // the trigger piece is long.
      for (a = [-1, 1])
        scale([a, 1, 1])
          translate([(width-2)/2, 0, 0])
            rotate([0, 0, -45])
              cube(10);
      for (z = [0, height])
        translate([0, 0, z])
          rotate([0, 0, 90])
            square_rail(1000);
    }
    
    // Spring channel: Rectangular top section.
    translate([
      -3.5,
      -length + spring_channel_length + 7,
      height - spring_channel_center_inset - spring_wire_radius
    ])
      scale([1, -1, 1])
        cube([7, 1000, 1000]);

    // Spring channel: Round bottom section.
    translate([
      0,
      -length + spring_channel_length,
      height - spring_channel_center_inset
    ])
      rotate([90, 0, 0])
        cylinder(1000, 3.5, 3.5);
  }
  
  // Spring post.
  translate([
    0,
    -length + spring_channel_length + spring_post_radius,
    height - spring_channel_center_inset - spring_wire_radius-eps
  ])
    spring_post();
}

// Front and back lugs for the receiver and release.
module outer_lugs(bottom_offset, flipped_print_aid=false) {
  height = receiver_height - bottom_offset;
  end_chamfer = 0.5;
  lug_aid_height = receiver_height - plate_thickness - loose_clearance;
  
  // The lugs themselves, which extends beyond the receiver in the X dimension.
  translate([0, lug_radius+1, height - lug_radius])
    hull()
      for (a = [-1, 1])
        translate([(receiver_width/2 + lug_width - eps)*a, 0, 0])
          rotate([0, a*90, 0])
            translate([0, 0, -end_chamfer])
              linear_extrude(end_chamfer, scale=(lug_radius-end_chamfer)/lug_radius)
                circle(lug_radius);
  
  if (flipped_print_aid) {
    translate([-receiver_width/2-lug_width, lug_radius+0.5, height-lug_radius-0.5])
      chamfered_cube([receiver_width+lug_width*2, lug_radius+0.5, lug_radius+0.5], 0.5);
  }
  
  difference() {
    translate([-receiver_width/2-lug_width, lug_radius-0.5, height-lug_aid_height])
      chamfered_cube([receiver_width+lug_width*2, lug_radius+1.5, lug_aid_height-lug_radius+0.5], 0.5);
      
    // We don't want the magazine lugs to actually rest against the print aid
    // (we want them tight against the receiver lugs). So cut out a cylinder
    // slightly wider than the magazine lugs, but centered where we expect the
    // magainze lugs to sit.
    bloat = 1.2;
    translate([0, lug_radius+1, height-lug_radius])
      rotate([-30, 0, 0])
        translate([-25, 0, -lug_radius*2])
          rotate([0, 90, 0])
            cylinder(50, lug_radius*bloat, lug_radius*bloat);
  }
      
  // The body on which the lugs are mounted, which has the same width as the
  // receiver. It is 1mm longer than the lug bar.
  translate([-receiver_width/2, 0, 0])
    chamfered_cube([receiver_width, lug_radius+1.5, height], 0.5);
  translate([-receiver_width/2, 0, 0])
    chamfered_cube([receiver_width, lug_radius*2+1, height-2], 0.5);
}

// The receiver encloses the two sliding parts and has lugs for attaching
// the magazine. It is printed in a single piece with the grip.
module receiver() {  
  difference() {
    // Exterior.
    translate([-receiver_width/2, 0, 0])
      cube([receiver_width, receiver_length, receiver_height]);
    
    // Inner channel for sliding parts.
    translate([-slide_channel_width/2, receiver_back_offset, -1])
      cube([slide_channel_width, 1000, 1000]);
    
    // Rail cavities for sliding parts.
    for (x = slide_channel_width/2 * [-1, 1])
      translate([x, 500+receiver_back_offset, receiver_height-slide_rail_drop])
        square_rail(1000, 1.5);
    
    // Recess for plate.
    translate([-500, receiver_length-plate_length, -1])
      cube([1000, 1000, plate_thickness+1]);
    
    // Rail cavities for plate placement guides.
    for (x = receiver_width*3/8 * [-1, 1])
      translate([x, receiver_length-(plate_length+2)/2, 2])
        square_rail(plate_length-2);

    // Chamfers against built plate for elephant foot.
    for (z = [0, receiver_height]) {
      for (x = slide_channel_width/2 * [-1, 1])
        translate([x, 500+receiver_back_offset, z])
          square_rail(1000, major_radius=0.5);
      for (x = receiver_width/2 * [-1, 1])
        translate([x, 0, z])
          square_rail(1000, major_radius=0.5);
    }
    translate([0, 2, receiver_height])
      rotate([0, 0, 90])
        square_rail(slide_channel_width+1, major_radius=0.6);
    translate([0, receiver_length, receiver_height])
      rotate([0, 0, 90])
        square_rail(1000, major_radius=0.5);
          
    // Front face side chamfers, where it meets the front lugs.
    for (x = receiver_width/2 * [-1, 1])
      translate([x, receiver_length, 0])
        rotate([90, 0, 0])
          square_rail(1000, major_radius=0.4);
  }
    
  // Rear lugs.
  translate([0, 1, 0])
    scale([1, -1, 1])
      outer_lugs(0, flipped_print_aid=true);
  
  // Grip.
  difference() {
    union() {
      translate([0, -4, 0])
        grip();
      
      // A plate near the top of the receiver to keep the mag from hitting my
      // thumb.
      difference() {
        // Avoid a computationally expensive hull of spheres.
        $fs = 0.6;
        
        hull() {
          for (x = 12 * [-1, 1], y = [8.5, 56])
            translate([x, y, 0.3])
              sphere(1.5);
          // Slant upwards.
          translate([-1, 8.5, 8]) cube([2, 56-8.5, 1]);
          // Slant forwards and backwards.
          translate([-1, 8.5-10, 0]) cube([2, 56-8.5+20, 1]);
        }
        // Cut out the middle.
        cube([receiver_width-2, 200, 200], center=true);
      }
    }
    
    // Clearance for trigger slide. This is gabled for nice printing.
    translate([0, receiver_back_offset, 0]) {
      gable = slide_channel_width/2+0.5;
      hull()
        for (y = [gable, 100], z = [0, 3])
          translate([0, y, z])
            scale([1, 1, -1])
              linear_extrude(gable*0.7, scale=0)
                translate([-gable, -gable, 0])
                  square(gable*2);
    }
        
    // Slot for the trigger finger.
    slot_height = trigger_finger_height;
    translate([-action_slot_width/2, trigger_back_offset, -slot_height]) 
      cube([action_slot_width, 100, slot_height]);
        
    // Gable the bottom again for nice printing.
    translate([0, trigger_back_offset, -slot_height+eps]) {
      gable = action_slot_width/2;
      hull()
        for (y = [gable, 100])
          translate([0, y, 0])
            scale([1, 1, -1])
              linear_extrude(gable*0.7, scale=0)
                translate([-gable, -gable, 0])
                  square(gable*2);
    }
  }
  
  // Brims.
  translate([0, 0, receiver_height - 0.2]) {
    linear_extrude(0.2) {
      translate([0, -7-brim_offset, 0])
        square([receiver_width+2*lug_width-1, 5], center=true);
      translate([0, receiver_length+2+brim_offset, 0])
        square([receiver_width-1, 5], center=true);
    }
  }
  // Add stiffness to make brims easier to remove.
  translate([0, -7-brim_offset, receiver_height-1.5])
    cube([receiver_width+2*lug_width-1, 1, 3], center=true);
  translate([0, receiver_length+2+brim_offset, receiver_height-1.5])
    cube([receiver_width-1, 1, 3], center=true);
}

// The front sliding part, which holds the mag in place.
module release() {
  // Distance between inner edges of end loops when the spring is relaxed.
  spring_length = 18;
  spring_tension = 0.5;
  
  width = slide_channel_width-2*loose_clearance;
  
  slide(
    release_slide_length,
    width,
    spring_length + spring_tension - 4*spring_post_radius,
    plate_thickness + loose_clearance,
    chamfer_back=false
  );
  outer_lugs(plate_thickness + loose_clearance);
  
  // Avoid a chamfer channel on the top and bottom between the two pieces.
  fillet_height = receiver_height - plate_thickness - loose_clearance;
  translate([-width/2, -1, 0])
    chamfered_cube([width, 3, fillet_height], 0.5);
  
  // Brims.
  linear_extrude(0.2) {
    translate([0, 8+brim_offset, 0])
      square([receiver_width+2*lug_width-1, 5], center=true);
    translate([0, -27-brim_offset, 0])
      square([width-1, 5], center=true);
  }
  // Add stiffness to make brims easier to remove.
  translate([0, 8+brim_offset, 1.5])
    cube([receiver_width+2*lug_width-1, 1, 3], center=true);
  translate([0, -27-brim_offset, 1.5])
    cube([width-1, 1, 3], center=true);
}

// Parameters for steps below.
step1_height = 4.7;
step2_height = 1.2;
step2_slope = 3;
function stepy(z) =
  z < (step1_height + step2_height)
  ? z - step2_slope * max(0, z - step1_height)
  : step1_height
    - step2_height * (step2_slope - 1)
    + stepy(z - step1_height - step2_height);

module steps() {
  outer_slope = 2;
  morph(dupfirst([
    [0],
    [30],
  ]))
    polygon([
      [-6.301, -15],
      [-6.301, 0.3898*$m[0] + 3*outer_slope],
      [-4.3, stepy($m[0])],
      [4.3, stepy($m[0])],
      [6.301, 0.3898*$m[0] + 3*outer_slope],
      [6.301, -15],
    ]);
}

// The rear sliding part, which pushes the bands up the back of the mag.
module trigger() {
  // Distance between inner edges of end loops when the spring is relaxed.
  spring_length = 43;
  spring_tension = 5;

  width = slide_channel_width-2*loose_clearance;

  intersection() {
    slide(
      trigger_slide_length,
      width,
      spring_length + spring_tension - 4*spring_post_radius,
      0
    );
    
    // Chamfer the bottom edges more aggressively to avoid needing supports
    // where it meets the trigger finger.
    translate([0, -500, -action_width/2])
      rotate([0, -45, 0])
        cube(1000);
    translate([0, 498-trigger_slide_length, 500])
      rotate([45, 0, 0])
        rotate([0, 0, 45])
          cube(1000, center=true);
  }
  
  // Subtract 1 to avoid the back of the trigger finger bumping the rear
  // wall.
  finger_y = receiver_back_offset-trigger_back_offset-2;
  
  translate([0, finger_y, 0])
    scale([1, -1, 1])
      trigger_finger();
  
  // Brims.
  translate([0, 0, -trigger_finger_height]) {
    linear_extrude(0.2) {
      translate([-6, finger_y-0.5+brim_offset, 0]) square([12, 32]);
      for (a = [-1, 1])
        scale([a, 1, 1])
          translate([action_width/2-0.5+brim_offset, finger_y-46, 0])
            square(action_width);
    }
    
    // Add stiffness to make brims easier to remove.
    translate([-1, finger_y-0.5+brim_offset+2, 0])
      cube([1.2, 30, 3]);
    for (a = [-1, 1])
      scale([a, 1, 1])
        translate([action_width/2-0.5+brim_offset+2, finger_y-46, 0])
          cube([1, 15, 3]);
  }  
  
  // Action which rises from rear of trigger slide.
  difference() {
    // The column.
    union() {
      translate([-action_width/2, 0, receiver_height+2]) {
        hull() {
          translate([0, -19, 0]) cube([action_width, 35, 0.1]);
          translate([0, -4, 0]) cube([action_width, 25, mag_height-2]);
        }
      }
      // Connect the column to the trigger slide.
      translate([-action_width/2, -19, receiver_height-1])
        cube([action_width, 18, 3]);
    }
    
    // Cut out the steps.
    translate([0, 11.8, receiver_height-3])
      scale([1, -1, 1])
        steps();
  }
}

// Glued under the front of the receiver to maintain the right spacing between the
// two sides.
module plate() {
  // The plate itself.
  difference() {
    union() {
      translate([-receiver_width/2, 0, 0])
        cube([receiver_width, plate_length, plate_thickness]);
      
      // Placement guide rails.
      for (x = receiver_width*3/8 * [-1, 1])
        translate([x, (plate_length-3)/2, 2])
          square_rail(plate_length-3);
    }
  
    // Front bottom chamfer.
    translate([0, plate_length, 0])
      rotate([0, 0, 90])
        square_rail(1000);
    
    // Side chamfers to match the receiver.
    for (x = receiver_width/2 * [-1, 1])
      translate([x, 0, 0])
        square_rail(1000, major_radius=0.5);

    // Rear bottom chamfer, just enough to counter elephant's foot.
    rotate([0, 0, 90])
      square_rail(1000, major_radius=0.3);
    
    // Slight depressions at corners, to counteract the natural curl during printing.
    translate([0, plate_length/2, 0])
      for (a = [0, 90, 180, 270])
        rotate([0, 0, a])
          translate([plate_length/2, -receiver_width/2, plate_thickness])
            rotate([0, 0, -45])
              square_rail(1000, major_radius=0.4);
  }
  
  // Platform at the back for the spring posts.
  platform_width = slide_channel_width - 2*loose_clearance;
  platform_length = plate_length - release_slide_length - 0.5;
  translate([-platform_width/2, 0, plate_thickness-eps])
    cube([
      platform_width,
      platform_length,
      receiver_height - plate_thickness - loose_clearance - spring_channel_center_inset - spring_wire_radius
    ]);
   
  // Front spring post.
  translate([0, platform_length/2, 0])
    for (a = [-1, 1])
      scale([1, a, 1])
        translate([
          0,
          spring_post_radius - platform_length/2,
          receiver_height - loose_clearance - spring_channel_center_inset - spring_wire_radius-eps
        ])
          spring_post();
}

// Difference to apply to the underside of the mag where it meets the top of the action.
module flared_magwell() {
  difference() {
    cube([7, 11, 6]);
    translate([7, -eps, 6]) {
      rotate([-90, 0, 0]) {
        cylinder(11+2*eps, 7, 7);
        translate([0, 0, -1])
          cylinder(2, 9, 7);
        translate([0, 0, 10])
          cylinder(2, 7, 9);
      }
    }
  }
}

module mag() {
  // Add 0.3 to tension the release spring when the mag is in place.
  tensioned_lug_spacing = outer_lug_spacing + 0.3;
  width = receiver_width + 2*lug_width;
  
  inner_wall_thickness = 3;
  outer_wall_thickness = 5;
  mag_plate_thickness = 2.5;
  mag_plate_length = tensioned_lug_spacing + 2*lug_radius;
  
  back_offset = 4;
  
  barrel_length = 70;
  barrel_height = 12;

  difference() {
    translate([0, 0, loose_clearance]) {
      // Barrel extension in front.
      translate([
        -(action_slot_width+2*inner_wall_thickness)/2,
        mag_plate_length/2-5,
        0
      ]) {
        hull() {
          translate([0, 0, mag_height - barrel_height])
            chamfered_cube([
              action_slot_width+2*inner_wall_thickness,
              barrel_length+5,
              barrel_height
            ], 1);
          translate([0, 0, 2])
            chamfered_cube([
              action_slot_width+2*inner_wall_thickness,
              2,
              mag_height-2
            ], 1);
        }
      }
        
      // Front fill between inner walls.
      translate([
        -(action_slot_width+2*inner_wall_thickness)/2,
        45-mag_plate_length/2,
        0
      ])
        chamfered_cube([
          action_slot_width+2*inner_wall_thickness,
          mag_plate_length-45,
          mag_height
        ], 1);
        
      // Top plate which approaches top of action.
      translate([
        -(action_slot_width+2*inner_wall_thickness)/2,
        24-mag_plate_length/2,
        mag_height-mag_plate_thickness
      ])
        chamfered_cube([
          action_slot_width+2*inner_wall_thickness,
          mag_plate_length-24,
          mag_plate_thickness
        ], 1);
              
      // In back there is the trigger slot.
      for (a = [-1, 1]) {
        scale([a, 1, 1]) {
          // Rear floor plates, with slot between them.
          translate([action_slot_width/2, back_offset-mag_plate_length/2, 0])
            chamfered_cube([
              (width-action_slot_width)/2,
              mag_plate_length-back_offset,
              mag_plate_thickness
            ], 1);
          
          difference() {
            // Inner walls.
            translate([action_slot_width/2, back_offset-mag_plate_length/2, 0])
              chamfered_cube([
                inner_wall_thickness,
                mag_plate_length-back_offset, 
                mag_height
              ], 1);
              
            // Cut out the steps.
            translate([0, back_offset-mag_plate_length/2, -0.2])
              steps();
          }
            
          // Outer walls.
          translate([
            width/2-outer_wall_thickness+1,
            back_offset-mag_plate_length/2+1,
            1
          ]) {
            outer_wall_height = mag_height*0.65;
            full_length = mag_plate_length-back_offset;
            morph(dupfirst([
              [0, 0, 0.1, 1],
              [mag_height*0.4, 0, 0.1+0.15*4/6.5, 1],
              [mag_height*0.65, 0.06, 0.25, 1],
              [mag_height*0.65+1, 0.065, 0.253, 0],
            ]))
              translate([
                0,
                $m[2]*(full_length-2),
                0
              ])
                offset(r=$m[3])
                  square([
                    outer_wall_thickness-2,
                    (1-$m[1]-$m[2])*(full_length-2)
                  ]);
          }
                            
          // Make the trenches shallower towards the front.
          scale([1, -1, 1])
            morph([
              [mag_plate_thickness-1, [1]],
              [mag_plate_thickness + mag_height*0.36, [0]],
            ])
              translate([-13, -mag_plate_length/2, 0])
                square([8, (mag_plate_length-back_offset-1)*$m[0]]);
        }
      }
    }
    
    // Slot in front for bands.
    torus_radius = 9;
    torus_thickness = 2;
    translate([
      0,
      mag_plate_length/2+barrel_length-torus_radius*1.5+1,
      mag_height-4.5
    ]) {
      scale([1, 1.5, 1]) {
        rotate([0, 0, 20]) {
          rotate_extrude(angle=140) {
            translate([torus_radius, 0, 0]) {
              hull() {
                circle(torus_thickness);
                translate([10, 0, 0])
                  square(torus_thickness*6, center=true);
              }
            }
          }
        }
      }
    }
    
    // Spring channel.
    translate([
      0,
      // Close the channel in front.
      mag_plate_length/2 - 2*lug_radius - 5,
      -spring_channel_center_inset
    ])
      rotate([90, 0, 0])
        cylinder(1000, 3.8, 3.8);
    
    for (a = [-1, 1])
      scale([a, 1, 1])
        translate([action_slot_width/2-eps, 12-mag_plate_length/2, 0])
          flared_magwell();
  }
  
  translate([0, 0, mag_height]) {
    linear_extrude(0.2) {
      // Front brim.
      hull()
        for (x = 10 * [-1, 1])
          translate([x, mag_plate_length/2+barrel_length+3+brim_offset, 0])
            circle(4);
      
      // Base plate for rear supports.
      translate([-10, -mag_plate_length/2, 0])
        square([20, 14]);
          
      // Detachable ears inside the back slot.
      for (a = [-1, 1])
        scale([a, 1, 1])
          translate([-action_slot_width/2-1+brim_offset, -mag_plate_length/2+13, 0])
            square([3, 10]);
          
      // Print aids for the supports for the outer walls.
      for (a = [-1, 1])
        scale([a, 1, 1])
          translate([12.3, 0, 0])
            hull()
              for (y = 1.05*mag_plate_length/2 * [-1, 1])
                translate([0, y, 0])
                  circle(6);
    }
  }
  
  // Side plates.
  side_plate_width = lug_width - loose_clearance;
  // Subtracting 2.5 just hits the tangent point between the lug
  // cutout and tuck-under lug.
  side_plate_length = tensioned_lug_spacing - 2.5;
  
  for (a = [-1, 1], b = [-1, 1]) {
    scale([a, b, 1]) {
      difference() {
        intersection() {
          translate([width/2-side_plate_width, -side_plate_length/2, -3*lug_radius])
            chamfered_cube([
              side_plate_width,
              side_plate_length/2+10,
              3*lug_radius+mag_plate_thickness+loose_clearance
            ], 1);
          
          // More aggressive inner chamfer ("flared magwell").
          translate([width/2, 500, 15.5])
            scale([1, 1, 3])
              rotate([90, 0, 0])
                cylinder(1000, 8, 8);
        }
      
        // Lug cutout.
        translate([-500, -tensioned_lug_spacing/2, -lug_radius])
          rotate([0, 90, 0])
            cylinder(1000, lug_radius, lug_radius);
      }
      
      // Tuck-under lug. Make it slightly smaller so that it
      // isn't another bearing surface.
      tuck_under_radius = lug_radius - 0.3;
      translate([width/2-side_plate_width, -tensioned_lug_spacing/2, -lug_radius]) {
        rotate([30, 0, 0]) {
          translate([0, 0, -lug_radius-tuck_under_radius]) {
            rotate([0, 90, 0]) {
              translate([0, 0, 1])
                linear_extrude(1, scale=tuck_under_radius/(tuck_under_radius-1))
                  circle(tuck_under_radius-1);
              translate([0, 0, 2])
                linear_extrude(side_plate_width-3)
                  circle(tuck_under_radius);
              translate([0, 0, side_plate_width-1])
                linear_extrude(1, scale=(tuck_under_radius-1)/tuck_under_radius)
                  circle(tuck_under_radius);
            }
          }
        } 
      }
    }
  }
}

module trigger_finger() {
  // Set this so that the trigger fully supports the front of its slide.
  length = trigger_slide_length - 27;
  
  translate([0, length, -trigger_finger_height]) {
    morph(dupfirst([
      [0],
      [trigger_finger_height+1],
    ])) {
      difference() {
        z = $m[0];

        // Chamfer the sharp edges on the bottom.
        chamfer = 0.6;
        offset(z < chamfer ? z-chamfer : 0) {
          hull() {        
            translate([
              0,
              trigger_finger_height * circ(z/trigger_finger_height - 0.5),
              0
            ])
              circle(action_width/2);
            
            translate([-action_width/2, -length, 0])
              square(action_width);
          }
        }
      }
    }
  }
}

module preview() {
  receiver();
  //color("red") translate([0, receiver_length+loose_clearance, plate_thickness+loose_clearance]) release();
  //color("blue") translate([0, receiver_length-plate_length, 0]) plate();
  color("orange") translate([0, receiver_back_offset+0*trigger_travel, 0]) scale([1, -1, 1]) trigger();
  //color("gray") translate([0, outer_lug_spacing/2-lug_radius-0.1, receiver_height]) mag();
}

module print() {
  translate([-35, -50, receiver_height])
    scale([1, 1, -1])
      receiver();

  release();
  
  translate([0, 20, 0])
    plate();
  
  translate([20, -10, trigger_finger_height])
    trigger();
  
  translate([50, -50, mag_height+loose_clearance])
    scale([1, 1, -1]) mag();
}

grip();
